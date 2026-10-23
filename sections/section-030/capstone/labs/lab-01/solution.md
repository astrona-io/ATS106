# Solution: Lock Down An Open Perses Server

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: anonymous requests are refused, sign-up is off, no global binding names `dana`, and `dana` can create dashboards in `inventory` but not in `billing`.

## Step 1: Read the current state

```sh
helm -n perses get values perses
kubectl -n perses get configmap perses -o jsonpath='{.data.config\.yaml}'
```

`security.enable_auth` is `false` and `authentication.disable_sign_up` is `false`. The provisioning folder and the mounted ConfigMap are correct, so the users and the `admin` role already exist. While authentication is off, Perses serves no role or role binding endpoints: `percli get globalrolebindings` finds nothing to read. The global bindings are in the provisioning ConfigMap, so read them there:

```sh
kubectl -n perses get configmap perses-provisioning -o jsonpath='{.data.admin\.json}'
```

Besides `admin`, there is a binding `dana-admin` that gives the `GlobalRole` `admin` to `dana`. Perses provisions the files in this ConfigMap again every minute (`provisioning.interval: 1m`), so a binding that is only deleted through the API comes back. Remove it from the ConfigMap. Open the ConfigMap in your editor:

```sh
kubectl -n perses edit configmap perses-provisioning
```

In `admin.json`, delete the object whose `metadata.name` is `dana-admin`, keep the `GlobalRole` `admin` and its binding for `admin`, and save. Then read `admin.json` again to check that only those two objects are left.

## Step 2: Turn on authentication and turn off sign-up

Keep the current values and add a file with the security settings:

```sh
helm -n perses get values perses -o yaml > perses-values-current.yaml
```

Save this as `perses-values-locked.yaml`:

```yaml
config:
  security:
    enable_auth: true
    authentication:
      disable_sign_up: true
      providers:
        enable_native: true
    authorization:
      guest_permissions:
        - actions: ["read"]
          scopes: ["*"]
envVars:
  - name: PERSES_SECURITY_ENCRYPTION_KEY
    value: "lab-only-encryption-key-32-bytes"
```

Apply both files, the new one last:

```sh
helm -n perses upgrade perses perses/perses --version 0.23.3 \
  -f perses-values-current.yaml -f perses-values-locked.yaml --wait
```

The pod restarts with an empty database. Provisioning loads the users, the `admin` role and binding, and the projects again from the ConfigMap, now without `dana-admin`; check it in step 3. The guest permissions keep `read` on every kind for logged-in users.

## Step 3: Remove any global access for dana

Start the port-forward again, and log in as the administrator:

```sh
percli login http://perses.localtest.me:8080 --username admin --password perses-admin
percli get globalrolebindings
```

If `dana-admin` is still listed, the ConfigMap still holds it: remove it there as in step 1, then delete it:

```sh
percli delete globalrolebinding dana-admin
```

## Step 4: Give dana a role in inventory

Save this as `role-dashboard-editor.yaml`:

```yaml
kind: Role
metadata:
  name: dashboard-editor
  project: inventory
spec:
  permissions:
    - actions: ["create", "update", "delete"]
      scopes: ["Dashboard"]
```

Save this as `rolebinding-dana-dashboard-editor.yaml`:

```yaml
kind: RoleBinding
metadata:
  name: dana-dashboard-editor
  project: inventory
spec:
  role: dashboard-editor
  subjects:
    - kind: User
      name: dana
```

Apply both:

```sh
percli apply -f role-dashboard-editor.yaml
percli apply -f rolebinding-dana-dashboard-editor.yaml
```

If you want this access to survive a restart of the lab's `emptyDir` database, add both resources to the ConfigMap `perses-provisioning` as well. The grader does not restart Perses.

## Step 5: Check from the outside and as dana

A request without a token, and an anonymous attempt to create a user:

```sh
curl -s -o /dev/null -w '%{http_code}\n' http://perses.localtest.me:8080/api/v1/projects
curl -s -o /dev/null -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' \
  -d '{"kind":"User","metadata":{"name":"intruder"},"spec":{"nativeProvider":{"password":"intruder-password"}}}' \
  http://perses.localtest.me:8080/api/v1/users
```

Both answer with an error code, not `200`. Then log in as `dana` and try one dashboard in each project. Save this as `dashboard-dana-check.yaml`:

```yaml
kind: Dashboard
metadata:
  name: dana-check
spec:
  duration: 1h
  panels:
    upTargets:
      kind: Panel
      spec:
        display:
          name: Scrape targets up
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: up
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 12
            height: 6
            content:
              $ref: "#/spec/panels/upTargets"
```

Log in as `dana` and apply it to both projects:

```sh
percli login http://perses.localtest.me:8080 --username dana --password dana-password
percli apply -f dashboard-dana-check.yaml --project inventory
percli apply -f dashboard-dana-check.yaml --project billing
```

The first apply succeeds and the second fails. Delete the test dashboard with `percli delete dashboard dana-check --project inventory`.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Turn on authentication but leave sign-up on | Anybody can create an account; the grader tries it |
| Keep `dana-admin` and add the project role | Permissions add up, so `dana` still changes everything |
| `helm upgrade` with only the new file | The provisioning mount disappears; after the restart there are no users, no administrator and no projects |
| Put the encryption key under `config:` | It works, but the key ends up in a ConfigMap in clear text |
