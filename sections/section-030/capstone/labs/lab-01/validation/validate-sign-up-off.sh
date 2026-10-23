#!/usr/bin/env bash
# PASS when: confirms an anonymous visitor cannot create a user.
set -uo pipefail

export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
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

code="$(perses_status POST /api/v1/users '{"kind":"User","metadata":{"name":"grader-signup"},"spec":{"nativeProvider":{"password":"grader-password"}}}')"
ADMIN_TOKEN="$(perses_login admin perses-admin)"
if [ "$(PERSES_TOKEN="$ADMIN_TOKEN" perses_status GET /api/v1/users/grader-signup)" = "200" ]; then
  PERSES_TOKEN="$ADMIN_TOKEN" perses_api DELETE /api/v1/users/grader-signup >/dev/null 2>&1 || true
  echo "FAIL: an anonymous request created a user (HTTP $code). Sign-up is still on."; exit 1
fi
echo "PASS: an anonymous request could not create a user (HTTP $code)."
exit 0
