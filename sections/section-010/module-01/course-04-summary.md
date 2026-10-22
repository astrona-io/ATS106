# Summary

Perses is an open-source dashboard server for observability data and a Cloud Native Computing Foundation (CNCF) sandbox project. It stores dashboards and the settings to reach data backends, and it forwards queries to those backends; it never stores metrics, logs, traces or profiles itself. Its dashboard format is an open specification, written in Go, CUE and TypeScript, so other tools and the embedded npm packages can read the same documents as the Perses server.

## What you learned

Everything in Perses is a resource: a JSON or YAML document with a `kind`, `metadata` and a `spec`. A project groups dashboards, datasources, variables, secrets, folders, roles and role bindings, and a project resource names its project in `metadata.project`. Global resources such as `GlobalDatasource`, `GlobalVariable`, `GlobalRole`, `User` and `Project` itself belong to the whole server. `percli login` stores the server URL in `~/.perses/config.json`, `percli project` selects a project, and `percli apply`, `get` and `describe` create, list and read resources. Apply updates a resource in place when it already exists.

A datasource can exist at three scopes: global, project and inside one dashboard. When a query names a datasource, the smallest scope that has the name wins. That makes deliberate overrides possible, and it also means a forgotten override hides a fix made at a larger scope.

A dashboard holds panels, each panel holds queries, each query names a datasource, and layouts point at panels with `$ref`. The server checks every document against the plugins' CUE schemas, but it does not check that a named datasource exists. The datasource proxy, at `/proxy/projects/<project>/datasources/<name>/` or `/proxy/globaldatasources/<name>/`, forwards a query to the URL stored in the datasource. Calling it directly tests a datasource on its own. The key facts to remember are these:

- Perses stores dashboards and datasource settings, not observability data.
- A `HTTPProxy` URL must work from inside the cluster, because Perses sends the query.
- The smallest scope that defines a datasource name is the one a dashboard uses.
- An empty panel has three usual causes: a refused document, a datasource that cannot reach its backend, or a query that names a datasource that does not exist.

<!-- astrona:playground:destroy -->
