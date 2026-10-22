# Summary

`percli` is the Perses command-line tool, and every command it runs is a call to the Perses REST API. Once authentication is on, every one of those calls needs a logged-in user, and role-based access control (RBAC) decides what that user may do.

## What you learned

`percli login` stores the server URL, the selected project and, when the server needs it, an access token in `~/.perses/config.json`, so that file must stay private. `percli project` selects a project, and `--project` or `--all` change it for one command. `percli get` lists, `describe` prints one resource, `apply` creates or updates in place, and `delete` removes. `-ojson` with `jq` makes the output scriptable, and `percli lint --online` checks a file against the plugins the server really has before you apply it.

With `security.enable_auth: true` and the native provider, users log in at `/api/auth/providers/native/login` and send the returned access token with every request; requests without a token are refused. The access token expires after 15 minutes by default. The first administrator, the users and the projects are provisioned from files, so they exist after every restart, and `disable_sign_up: true` stops anybody from creating an account. `guest_permissions` give every logged-in user a base, such as `read` on every kind. The 32-byte encryption key belongs in an environment variable, which the chart stores in a Secret.

Permissions come from four resources: `Role` and `RoleBinding` inside one project, `GlobalRole` and `GlobalRoleBinding` for the whole server. A permission lists actions and resource kinds, permissions only add up, and a binding's role cannot be changed after it is created. Roles travel in the access token, so a user logs in again after a change, and the only real test of a permission is to act as that user. The key facts to remember are these:

- Give project access with a `Role` and a `RoleBinding`, never with a global binding.
- Provision the first administrator before authentication is turned on.
- Turn off sign-up on any shared server.
- Test permissions as the user, with a fresh login.

<!-- astrona:playground:destroy -->
