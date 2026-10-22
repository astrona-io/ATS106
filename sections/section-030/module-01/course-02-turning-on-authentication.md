# Turning On Authentication

With authentication off, Perses treats every request the same: anybody who reaches the server can read and change anything. Turning authentication on makes every request carry a token for a known user, and that is what makes permissions possible at all. This part turns on the native provider, creates the first users and a global administrator so they exist after every restart, and shows what changes for the API and for `percli`.

## What authentication changes

**Authentication** is how the server checks who sent a request. Perses can check users itself, with the **native provider**: users and their passwords live in the Perses database. It can also hand the check to an outside identity provider through OpenID Connect (OIDC) or OAuth, or to Kubernetes. This course uses the native provider.

When `security.enable_auth` is `true`, a client first logs in. With the native provider, that is a `POST` to `/api/auth/providers/native/login` with a user name and a password. Perses answers with an **access token**, a JSON Web Token (JWT) that the client sends in the `Authorization: Bearer` header of every later request, and a refresh token to get a new one. The access token lives 15 minutes by default, and the refresh token 24 hours. A request without a valid token is refused.

**Authorization** then decides what the logged-in user may do. With authentication on, the native authorization provider is used, and its permissions come from roles and role bindings, plus an optional set of `guest_permissions` that every logged-in user gets.

## The first users and the first administrator

There is a chicken-and-egg problem. Once authentication is on, you need an administrator to create anything, including other users. And in this playground the database is an `emptyDir`, so whatever you create through the API is gone after the restart that turning on authentication causes.

The answer is provisioning: Perses loads resource files from a folder at start. You provision the users, a `GlobalRole` with every permission, a `GlobalRoleBinding` that gives it to the administrator, and the two projects with their datasources so they survive the restart too.

<!-- astrona:playground:renew -->

Save this as `configmap-perses-provisioning.yaml`. The passwords are lab-only; Perses hashes a native password before it stores it:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: perses-provisioning
  namespace: perses
data:
  users.json: |
    [
      {"kind": "User", "metadata": {"name": "admin"}, "spec": {"nativeProvider": {"password": "perses-admin"}}},
      {"kind": "User", "metadata": {"name": "dana"}, "spec": {"nativeProvider": {"password": "dana-password"}}}
    ]
  admin.json: |
    [
      {"kind": "GlobalRole", "metadata": {"name": "admin"}, "spec": {"permissions": [{"actions": ["*"], "scopes": ["*"]}]}},
      {"kind": "GlobalRoleBinding", "metadata": {"name": "admin"}, "spec": {"role": "admin", "subjects": [{"kind": "User", "name": "admin"}]}}
    ]
  projects.json: |
    [
      {"kind": "Project", "metadata": {"name": "inventory"}, "spec": {}},
      {"kind": "Project", "metadata": {"name": "billing"}, "spec": {}},
      {"kind": "Datasource", "metadata": {"name": "prometheus", "project": "inventory"}, "spec": {"default": true, "plugin": {"kind": "PrometheusDatasource", "spec": {"proxy": {"kind": "HTTPProxy", "spec": {"url": "http://prometheus.observability:9090"}}}}}},
      {"kind": "Datasource", "metadata": {"name": "prometheus", "project": "billing"}, "spec": {"default": true, "plugin": {"kind": "PrometheusDatasource", "spec": {"proxy": {"kind": "HTTPProxy", "spec": {"url": "http://prometheus.observability:9090"}}}}}}
    ]
```

Apply it:

```sh
kubectl apply -f configmap-perses-provisioning.yaml
```

## The values that turn it on

Two values files go into the upgrade. The first is the base values this course installs with. Save this as `perses-values.yaml`:

```yaml
fullnameOverride: perses
image:
  version: v0.54.0
service:
  type: ClusterIP
  port: 8080
config:
  security:
    readonly: false
    enable_auth: false
    cookie:
      same_site: lax
      secure: false
  database:
    file:
      folder: /perses
      extension: json
persistence:
  enabled: false
```

The second turns on authentication, turns off sign-up, gives logged-in users read access, mounts the ConfigMap, and passes the encryption key through an environment variable. Save this as `perses-values-auth.yaml`:

```yaml
config:
  security:
    enable_auth: true
    authentication:
      disable_sign_up: true
      providers:
        enable_native: true
    authorization:
      provider:
        native:
          guest_permissions:
            - actions: ["read"]
              scopes: ["*"]
  provisioning:
    interval: 1m
    folders:
      - /etc/perses/provisioning-files
envVars:
  - name: PERSES_SECURITY_ENCRYPTION_KEY
    value: "lab-only-encryption-key-32-bytes"
volumes:
  - name: provisioning-files
    configMap:
      name: perses-provisioning
volumeMounts:
  - name: provisioning-files
    mountPath: /etc/perses/provisioning-files
    readOnly: true
```

Each setting has one job. `enable_auth` requires a token on every request. `enable_native` lets Perses check users itself. `disable_sign_up` removes the endpoint that lets anybody create a user, so only administrators create users. `guest_permissions` gives every logged-in user `read` on every kind, so people can view dashboards without a role. The encryption key is exactly 32 bytes and goes through `envVars`, which the chart stores in a Secret instead of the ConfigMap.

Apply both files:

```sh
helm -n perses upgrade perses perses/perses --version 0.23.3 \
  -f perses-values.yaml -f perses-values-auth.yaml --wait
```

## What changed

Start the port-forward again, then send a request without a token:

```sh
curl -s -o /dev/null -w '%{http_code}\n' http://perses.localtest.me:8080/api/v1/projects
```

The status code is an error in the 400 range, not `200`: the request carries no token, so the server refuses it. Now log in through the API as the administrator and use the token:

```sh
ACCESS_TOKEN=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"login":"admin","password":"perses-admin"}' \
  http://perses.localtest.me:8080/api/auth/providers/native/login | jq -r '.access_token')
curl -s -H "Authorization: Bearer $ACCESS_TOKEN" http://perses.localtest.me:8080/api/v1/projects | jq -r '.[].metadata.name'
```

The projects `inventory` and `billing` are listed: they came back from the provisioned files after the restart. `percli` does the same login for you:

```sh
percli login http://perses.localtest.me:8080 --username admin --password perses-admin
percli whoami
percli get project
```

`percli whoami` now names `admin`. `percli` stored the token in `~/.perses/config.json`; when it expires, `percli refresh` gets a new one, or you log in again.

Authentication is on, the administrator exists after every restart, and nobody can create an account by themselves. `dana` can log in too, but with only the guest permissions she can read and change nothing. Giving her exactly the access she needs is the job of roles.

## Common pitfalls

> [!WARNING]
> - **Turning on authentication without an administrator.** Nobody can then create users or roles. Provision a user and a `GlobalRoleBinding` to a full `GlobalRole` first.
> - **Leaving sign-up on.** Without `disable_sign_up: true`, anybody who reaches the server can create an account for themselves.
> - **An encryption key of the wrong length.** The key must be exactly 32 bytes, because Perses uses AES-256. Pass it through `envVars`, not `config:`.
> - **Forgetting that tokens expire.** After 15 minutes `percli` and scripts are refused again. Run `percli refresh` or log in again.
