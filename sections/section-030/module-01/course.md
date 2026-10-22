# Secure Perses And Work With percli

Your Perses server answers anybody who can reach it, and anybody can delete a dashboard. Turning on authentication fixes that, but then every request and every `percli` command needs a logged-in user, and each user needs the right permissions. This module works through all three: `percli` itself, authentication, and the roles that decide what a user may do.

Perses is an open-source dashboard server for observability data. `percli` is its command-line tool: it calls the Perses REST API to log in, read and change resources. With authentication on, the server checks every request against a token, and its role-based access control (RBAC) decides whether that user may do it.

The module has three parts. **Working With percli** covers logging in, the configuration file, selecting a project, and getting, describing, applying, deleting and linting resources. **Turning On Authentication** switches on the native provider with provisioned users and a global administrator, and shows what changes. **Roles And Role Bindings** gives one user edit rights in one project and proves the limits by logging in as that user; a graded lab follows it.

## Learning objectives

After this module you can:

- Log `percli` in to a server, with and without a user name and password, and find its configuration file.
- Select a project and get, describe, apply, delete and lint resources with `percli`.
- Turn on authentication with the native provider through the Helm values, and turn off sign-up.
- Provision users and a global administrator so they exist after every restart.
- Write a `Role` and a `RoleBinding`, and tell them from `GlobalRole` and `GlobalRoleBinding`.
- Check what a user can and cannot do by logging in as that user.

## Before you start

You need Kubernetes basics, `helm upgrade` with values files, and `jq` for reading JSON. You should know that Perses stores resources such as projects, dashboards and datasources, each a JSON or YAML document with `kind`, `metadata` and `spec`, and that every dashboard belongs to a project.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** in the namespace `perses`, the Helm release `perses` with the chart 0.23.3. Authentication is off. Two projects exist, `inventory` and `billing`, each with a datasource `prometheus` that points at `http://prometheus.observability:9090`. The database is an `emptyDir`, so a restart deletes every resource that is not provisioned. The playground puts `percli` v0.54.0 and Helm 3.22.1 on your machine.

Perses answers at `http://perses.localtest.me:8080`. Keep this port-forward running in a second terminal, and start it again after every restart of the Perses pod:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

If your network blocks the name `perses.localtest.me`, add `127.0.0.1 perses.localtest.me` to `/etc/hosts`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
