#!/usr/bin/env bash
# OS prep for the ATS106 section 010 module 01 playground (`ats-106-playground-030-01`).
#
# Environment preparation only. There is no task and no grading. This script:
#   1. puts Helm and percli (pinned) on the PATH,
#   2. makes perses.localtest.me resolve to the Perses Service inside the cluster,
#   3. starts Prometheus and the tester pod,
#   4. installs Perses v0.54.0 with the perses Helm chart 0.23.3.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

HELM_VERSION="3.22.1"
PERSES_VERSION="0.54.0"
PERSES_CHART_VERSION="0.23.3"
PERSES_HOST="perses.localtest.me"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Pin the tools rather than accepting whatever is on the machine.
have_helm=""
command -v helm >/dev/null 2>&1 && have_helm=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_helm" != "$HELM_VERSION" ]; then
  echo "[playground] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
# percli ships in the Perses release archive, next to the server binary.
have_percli=""
command -v percli >/dev/null 2>&1 && have_percli=$(percli version 2>/dev/null | awk '/[Vv]ersion/{print $NF; exit}' | sed 's/^v//')
if [ "$have_percli" != "$PERSES_VERSION" ]; then
  echo "[playground] Downloading percli ${PERSES_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/perses/perses/releases/download/v${PERSES_VERSION}/perses_${PERSES_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" percli
  install -m 0755 "$WORK/percli" "$BIN_DIR/percli"
fi
helm version --short
percli version || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# One address for the reader's machine and the cluster: perses.localtest.me
# resolves to 127.0.0.1 on the machine (reached through a port-forward), and
# this CoreDNS block sends the same name to the Perses Service in the cluster.
# The answer is rewritten back to the asked name: Go programs ignore DNS
# answers whose name differs from the question.
if ! kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$PERSES_HOST"; then
  echo "[playground] Adding the CoreDNS rewrite for ${PERSES_HOST}..."
  COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex perses\\.localtest\\.me perses.perses.svc.cluster.local"
        print "        answer name perses\\.perses\\.svc\\.cluster\\.local perses.localtest.me"
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
echo "[playground] Starting Prometheus and the tester pod..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n observability rollout status deployment/prometheus --timeout=300s
kubectl -n observability rollout status deployment/tester --timeout=300s

echo "[playground] Installing Perses (chart ${PERSES_CHART_VERSION})..."
helm repo add perses https://perses.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update perses >/dev/null
helm upgrade --install perses perses/perses --version "$PERSES_CHART_VERSION" \
  --namespace perses --create-namespace \
  --values "$MANIFEST_DIR/perses-values.yaml" \
  --wait --timeout 10m


# Starting content for this module.
PERSES_URL="http://perses.localtest.me:8080"
PERSES_CHART_VERSION="0.23.3"
PROMETHEUS_URL="http://prometheus.observability:9090"

# Runs a command in the tester pod (curl and jq) inside the cluster.
tester() { kubectl -n observability exec -i deploy/tester -- "$@"; }

# auth_args: prints nothing, but fills AUTH_ARGS with a bearer token header
# when PERSES_TOKEN is set. Bash 3.2-safe empty-array handling below.
set_auth_args() {
  AUTH_ARGS=()
  if [ -n "${PERSES_TOKEN:-}" ]; then
    AUTH_ARGS=(-H "Authorization: Bearer ${PERSES_TOKEN}")
  fi
}

# perses_api METHOD PATH [JSON]: calls the Perses REST API from the tester pod
# and prints the response body. Fails on an HTTP error.
perses_api() {
  local method="$1" path="$2" body="${3:-}"
  set_auth_args
  if [ -n "$body" ]; then
    printf '%s' "$body" | tester curl -fsS -X "$method" ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} \
      -H 'Content-Type: application/json' --data-binary @- "$PERSES_URL$path"
  else
    tester curl -fsS -X "$method" ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} "$PERSES_URL$path"
  fi
}

# perses_status METHOD PATH [JSON]: prints only the HTTP status code.
perses_status() {
  local method="$1" path="$2" body="${3:-}"
  set_auth_args
  if [ -n "$body" ]; then
    printf '%s' "$body" | tester curl -s -o /dev/null -w '%{http_code}' -X "$method" \
      ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} -H 'Content-Type: application/json' --data-binary @- "$PERSES_URL$path"
  else
    tester curl -s -o /dev/null -w '%{http_code}' -X "$method" \
      ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} "$PERSES_URL$path"
  fi
}

# upsert COLLECTION_PATH NAME JSON: updates the resource, or creates it when
# it does not exist yet.
upsert() {
  if [ "$(perses_status GET "$1/$2")" = "200" ]; then
    perses_api PUT "$1/$2" "$3" >/dev/null
  else
    perses_api POST "$1" "$3" >/dev/null
  fi
}

# perses_login USER PASSWORD: prints an access token for a native user.
perses_login() {
  perses_api POST /api/auth/providers/native/login \
    "{\"login\":\"$1\",\"password\":\"$2\"}" | tester jq -r '.access_token'
}

# proxy_query PROXY_PATH QUERY: runs a PromQL instant query through the Perses
# datasource proxy and prints the number of series returned (0 on error).
proxy_query() {
  local count
  set_auth_args
  count="$(tester curl -fsS -X POST ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} \
    --data-urlencode "query=$2" "$PERSES_URL$1/api/v1/query" 2>/dev/null \
    | tester jq -r 'if .status == "success" then (.data.result | length) else 0 end' 2>/dev/null)"
  echo "${count:-0}"
}

# manifest_dir: prints the folder that holds this environment's manifests.
manifest_dir() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for candidate in "$here/../manifests" "./manifests" "$here/manifests"; do
    [ -d "$candidate" ] && { echo "$candidate"; return 0; }
  done
  echo "manifests"
}

# wait_for_perses: waits until the Perses health endpoint answers.
wait_for_perses() {
  for _ in $(seq 1 90); do
    tester curl -fsS "$PERSES_URL/api/v1/health" >/dev/null 2>&1 && return 0
    sleep 3
  done
  echo "Perses did not answer in time." >&2
  return 1
}

# restart_perses: deletes the Perses pod. With the file database on an
# emptyDir, every resource that is not provisioned is gone afterwards.
restart_perses() {
  kubectl -n perses delete pod perses-0 --wait=true >/dev/null
  kubectl -n perses rollout status statefulset/perses --timeout=300s >/dev/null
  wait_for_perses
}

# record_baseline KEY VALUE / baseline KEY: values the graders compare against.
record_baseline() {
  # Create the ConfigMap only once; applying a one-key ConfigMap would erase
  # the values recorded before it.
  kubectl -n perses get configmap lab-baseline >/dev/null 2>&1 || \
    kubectl -n perses create configmap lab-baseline >/dev/null
  kubectl -n perses patch configmap lab-baseline --type merge -p "{\"data\":{\"$1\":\"$2\"}}" >/dev/null
}
baseline() { kubectl -n perses get configmap lab-baseline -o jsonpath="{.data.$1}"; }

# project_json NAME
project_json() { printf '{"kind":"Project","metadata":{"name":"%s"},"spec":{}}' "$1"; }

# datasource_json NAME PROJECT URL: a Prometheus datasource reached through
# the Perses proxy. An empty PROJECT makes it a GlobalDatasource.
datasource_json() {
  if [ -n "$2" ]; then
    printf '{"kind":"Datasource","metadata":{"name":"%s","project":"%s"},"spec":{"default":true,"plugin":{"kind":"PrometheusDatasource","spec":{"proxy":{"kind":"HTTPProxy","spec":{"url":"%s"}}}}}}' "$1" "$2" "$3"
  else
    printf '{"kind":"GlobalDatasource","metadata":{"name":"%s"},"spec":{"default":true,"plugin":{"kind":"PrometheusDatasource","spec":{"proxy":{"kind":"HTTPProxy","spec":{"url":"%s"}}}}}}' "$1" "$3"
  fi
}

# dashboard_json NAME PROJECT DATASOURCE_NAME QUERY: one TimeSeriesChart panel.
dashboard_json() {
  printf '{"kind":"Dashboard","metadata":{"name":"%s","project":"%s"},"spec":{"display":{"name":"%s"},"duration":"1h","panels":{"upTargets":{"kind":"Panel","spec":{"display":{"name":"Scrape targets up"},"plugin":{"kind":"TimeSeriesChart","spec":{}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"%s","datasource":{"kind":"PrometheusDatasource","name":"%s"}}}}}]}}},"layouts":[{"kind":"Grid","spec":{"items":[{"x":0,"y":0,"width":12,"height":6,"content":{"$ref":"#/spec/panels/upTargets"}}]}}]}}' "$1" "$2" "$1" "$4" "$3"
}

# role_json NAME PROJECT: a Role that may create, update and delete dashboards.
role_json() {
  printf '{"kind":"Role","metadata":{"name":"%s","project":"%s"},"spec":{"permissions":[{"actions":["create","update","delete"],"scopes":["Dashboard"]}]}}' "$1" "$2"
}

# rolebinding_json NAME PROJECT ROLE USER
rolebinding_json() {
  printf '{"kind":"RoleBinding","metadata":{"name":"%s","project":"%s"},"spec":{"role":"%s","subjects":[{"kind":"User","name":"%s"}]}}' "$1" "$2" "$3" "$4"
}

# helm_upgrade_perses VALUES_FILE...: upgrades the Perses release with the
# given values files (later files win) and waits for it.
helm_upgrade_perses() {
  local args=()
  for file in "$@"; do args+=(--values "$file"); done
  helm upgrade perses perses/perses --version "$PERSES_CHART_VERSION" \
    --namespace perses "${args[@]}" --wait --timeout 10m >/dev/null
}

echo "[playground] Creating the projects inventory and billing, each with a Prometheus datasource..."
wait_for_perses
for project in inventory billing; do
  upsert /api/v1/projects "$project" "$(project_json "$project")"
  upsert "/api/v1/projects/$project/datasources" prometheus "$(datasource_json prometheus "$project" "$PROMETHEUS_URL")"
done

echo "[playground] Ready."
kubectl -n perses get pods
echo "[playground] Start the port-forward in a second terminal before you use percli or the browser:"
echo "  kubectl -n perses port-forward svc/perses 8080:8080"
echo "  then open http://perses.localtest.me:8080"
