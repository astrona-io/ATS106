# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Perses authentication and authorization

## Scenario

A Perses server was set up for a demo and then left running for the whole company. The users `admin` (lab-only password `perses-admin`) and `dana` (lab-only password `dana-password`) are provisioned from the ConfigMap `perses-provisioning`, together with a `GlobalRole` `admin`, its `GlobalRoleBinding` for `admin`, and the projects `inventory` and `billing`. But:

- authentication is off, so anybody who reaches the server can change anything;
- once authentication is on, anybody could still create an account for themselves;
- to "get her started", somebody gave `dana` the global administrator role.

`dana` works in the `inventory` team. She must be able to create, change and delete dashboards in `inventory`, and nothing more.

Perses is the Helm release `perses` in the namespace `perses`, chart `perses/perses` version `0.23.3`. Read its values with `helm -n perses get values perses`.

## Your task

1. Turn on authentication with the native provider, and turn off sign-up, through the Helm release's values. Use a 32-byte encryption key passed as an environment variable.
2. Remove `dana`'s global administrator access.
3. Give `dana` the right to create, update and delete dashboards in `inventory` only.

## Constraints

- Change the installation only with `helm upgrade` on the release `perses`. Keep the values that are correct, including the provisioning of `perses-provisioning`.
- Do not change the users' passwords, and keep `admin` a global administrator.
- Logged-in users must still be able to read dashboards in every project.

## Done when

- A request without a token is refused.
- An anonymous request cannot create a user.
- No `GlobalRoleBinding` names `dana`.
- Logged in as `dana`, a new dashboard can be created in `inventory` and cannot be created in `billing`.
