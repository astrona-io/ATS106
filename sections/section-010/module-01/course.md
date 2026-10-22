# Find Your Way Around Perses

A dashboard shows an empty panel. The panel has a query, the query names a datasource, and the datasource names a URL, but the user interface does not tell you which of these links is broken. To find out, you need to know what Perses stores and how one resource refers to another.

Perses is an open-source dashboard server for observability data, and a Cloud Native Computing Foundation (CNCF) sandbox project. Everything it shows comes from resources: JSON or YAML documents with a `kind`, `metadata` and `spec`, stored by the Perses server and served through its REST API. This module reads those resources with `percli`, the Perses command-line tool, and with the API itself.

The module has three parts. **What Perses Is And Where It Fits** explains what Perses is for, the open dashboard specification, and the difference between the Perses server and the embedded npm packages. **Projects, Resources And Scopes** creates a project and a datasource with `percli` and explains the scopes a datasource can live in. **A First Dashboard And The Datasource Proxy** applies a dashboard, takes it apart, and follows one query through the Perses proxy to Prometheus; a graded lab follows it.

## Learning objectives

After this module you can:

- Say what Perses is, what its open specification is for, and how the server differs from the embedded packages.
- Log `percli` in to a Perses server and select a project.
- Name the Perses resource kinds and the project they belong to, and tell project resources from global ones.
- Create a project and a Prometheus datasource with `percli apply`.
- Explain the global, project and dashboard scopes of a datasource and which one a dashboard uses.
- Read a dashboard: its panels, their queries, the layout and each query's datasource reference.
- Send a query through the Perses datasource proxy and read the result.

## Before you start

You need Kubernetes basics: namespaces, Services, StatefulSets and the commands `kubectl get`, `kubectl logs` and `kubectl port-forward`. You should know what a metric is and be able to read a short Prometheus query such as `up`. You do not need to know Perses.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** in the namespace `perses`, installed with the `perses` Helm chart. Perses has no projects yet, and authentication is off, so every request is allowed. **Prometheus v3.15.1** runs in the namespace `observability` at `http://prometheus.observability:9090` and scrapes itself, so the metric `up` always has data. The playground also puts `percli` v0.54.0 on your machine.

Perses answers at `http://perses.localtest.me:8080`. Inside the cluster that name already points at Perses. On your machine, keep this port-forward running in a second terminal while you work:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

The name `perses.localtest.me` is a public DNS name for `127.0.0.1`, your own machine, so the port-forward answers it. If your network blocks that name, add `127.0.0.1 perses.localtest.me` to `/etc/hosts`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
