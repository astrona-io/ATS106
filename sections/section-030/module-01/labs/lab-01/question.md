# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Perses authorization

## Scenario

Authentication is on. Two lab-only users exist: `admin` (password `perses-admin`), a global administrator, and `dana` (password `dana-password`), who can log in but only read. The projects `inventory` and `billing` exist.

`dana` has joined the `inventory` team. She must be able to create, change and delete dashboards in `inventory`. The `billing` team does not want her to change anything of theirs.

Perses answers at `http://perses.localtest.me:8080`. Start the port-forward in a second terminal first:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Your task

1. Give `dana` the right to create, update and delete dashboards in the project `inventory`.
2. Make sure she gets no new rights anywhere else.

## Constraints

- Keep authentication on.
- Do not give `dana` a `GlobalRoleBinding`, and do not change her password or the administrator's.
- Do not change the Perses installation.

## Done when

- A request without a token is still refused.
- Logged in as `dana`, a new dashboard can be created in `inventory`.
- Logged in as `dana`, a new dashboard cannot be created in `billing`.
- No `GlobalRoleBinding` names `dana`.
