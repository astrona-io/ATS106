# Roles And Role Bindings

With authentication on, `dana` can log in, but she can only read. The `inventory` team wants her to edit their dashboards, and the `billing` team does not want her touching theirs. Making her a global administrator would solve the first wish and break the second. This part gives her exactly one permission set in exactly one project, and proves the limits by logging in as her.

## Four resources for permissions

Perses uses role-based access control (RBAC): permissions are grouped in roles, and bindings give roles to users. The model follows Kubernetes RBAC, and it has four resources.

| Resource | Scope | What it does |
| --- | --- | --- |
| `Role` | One project | A list of permissions inside that project |
| `RoleBinding` | One project | Gives a `Role` of the same project to users |
| `GlobalRole` | Whole server | A list of permissions on global resources and on every project |
| `GlobalRoleBinding` | Whole server | Gives a `GlobalRole` to users |

A permission is a list of **actions** (`read`, `create`, `update`, `delete`, or `*` for all) and a list of **scopes**, which are resource kinds such as `Dashboard` or `Datasource`, or `*` for every kind. A `Role` cannot target global kinds. Permissions only add up; there is no "deny". So a user's access is the sum of every role bound to them, plus the `guest_permissions` every logged-in user has.

Two more rules matter. When a user creates a project, Perses makes that user the project's owner, with full control over it. And once a binding exists, you cannot change which role it points at: to bind another role, delete the binding and create a new one. That prevents a quiet edit from granting more than intended.

## A Role and a RoleBinding for one project

The commands below need the playground with authentication on, as the previous steps of this module set it up: the users `admin` (lab-only password `perses-admin`) and `dana` (lab-only password `dana-password`), and the projects `inventory` and `billing`.

<!-- astrona:playground:renew -->

Log in as the administrator, who may create roles:

```sh
percli login http://perses.localtest.me:8080 --username admin --password perses-admin
```

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

Then check the result:

```sh
percli get roles --project inventory
percli get rolebindings --project inventory
```

The `Role` grants the three write actions on dashboards. Reading is already covered by the guest permission `read` on `*`, so the role does not repeat it. The `RoleBinding` gives the role to `dana`, and both live in `inventory`, so the permission ends at the project's edge.

## Proving the limits as dana

The only real test of a permission is to act as the user. Roles and role bindings travel inside the user's access token, so `dana` must log in after the binding exists:

```sh
percli login http://perses.localtest.me:8080 --username dana --password dana-password
percli whoami
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

The file has no project, so `--project` decides where it goes. Apply it to both projects:

```sh
percli apply -f dashboard-dana-check.yaml --project inventory
percli apply -f dashboard-dana-check.yaml --project billing
```

The first apply succeeds: `dana` may create dashboards in `inventory`. The second fails with a permission error: in `billing` she has only the guest `read`. That pair of results is the proof. Delete the test dashboard in `inventory` with `percli delete dashboard dana-check --project inventory`.

Compare this with the shortcut the task forbids: a `GlobalRoleBinding` to the `admin` `GlobalRole`. Both applies would succeed, and `dana` could also delete users, change global datasources and rewrite every team's dashboards.

You can now write a role for exactly the actions and kinds a user needs, bind it in one project, and prove the result by acting as that user. That is the skill the lab asks for.

## Common pitfalls

> [!WARNING]
> - **Testing as the administrator.** The administrator can do everything, so a test as `admin` proves nothing. Log in as the user.
> - **Testing with an old token.** Roles travel in the access token. Log in again after you change a binding.
> - **Using a global binding for a project task.** A `GlobalRoleBinding` applies to every project. Use a `Role` and a `RoleBinding` in the project.
> - **Editing a binding's role.** Perses refuses to change the role a binding points at. Delete the binding and create a new one.

## Your mission: Give A User Edit Rights On One Project

You can now give one user write access in one project with a `Role` and a `RoleBinding`. The lab starts with authentication on and `dana` able to read only, and asks you to let her create and change dashboards in `inventory` and nowhere else.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-106-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS106.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-106-lab-030-01
astrona start ats-106-playground-030-01
```
