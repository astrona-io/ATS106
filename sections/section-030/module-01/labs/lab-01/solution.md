# Solution: Give A User Edit Rights On One Project

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: authentication is still on, `dana` can create a dashboard in `inventory`, she cannot in `billing`, and no global binding names her.

## Step 1: Log in as the administrator

With the port-forward running:

```sh
percli login http://perses.localtest.me:8080 --username admin --password perses-admin
percli whoami
percli get project
```

`percli whoami` names `admin`, and both projects are listed.

## Step 2: Write the Role

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

Apply it:

```sh
percli apply -f role-dashboard-editor.yaml
```

The guest permissions already give every logged-in user `read`, so the role only adds the three write actions, and only on dashboards.

## Step 3: Bind it to dana

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

Apply it and check both resources:

```sh
percli apply -f rolebinding-dana-dashboard-editor.yaml
percli get roles --project inventory
percli get rolebindings --project inventory
```

## Step 4: Prove it as dana

Roles travel in the access token, so log in as `dana` now, after the binding exists:

```sh
percli login http://perses.localtest.me:8080 --username dana --password dana-password
```

Save this as `dashboard-dana-check.yaml`:

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

Apply it to both projects:

```sh
percli apply -f dashboard-dana-check.yaml --project inventory
percli apply -f dashboard-dana-check.yaml --project billing
```

The first apply succeeds and the second fails with a permission error. Remove the test dashboard:

```sh
percli delete dashboard dana-check --project inventory
```

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Bind `dana` to the `admin` `GlobalRole` | She can change `billing`, users and global datasources; the grader rejects it |
| A `GlobalRole` limited to dashboards, with a `GlobalRoleBinding` | She can change dashboards in every project, including `billing` |
| Turn authentication off | Anybody can change everything; the grader checks that anonymous requests are refused |
| Test as `admin` | The administrator may do everything, so the test proves nothing about `dana` |
