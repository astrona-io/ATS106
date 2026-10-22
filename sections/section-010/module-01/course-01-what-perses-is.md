# What Perses Is And Where It Fits

Before you change anything in Perses, you need to know what kind of program it is and what it is not. Perses does not store metrics, logs or traces. It stores dashboards and the settings to reach the systems that do store that data, and it sends queries to them. This part explains that split, the open dashboard specification behind it, and the two ways to use Perses. It ends with a first look at a running server.

## A dashboard server, not a database

Perses is an open-source dashboard server for observability data. Observability data is what a system reports about itself: metrics (numbers over time), logs (lines of text), traces (the path of one request through several services) and profiles (where a program spends its time). Perses connects to the systems that store this data, such as Prometheus for metrics, Loki for logs, Tempo for traces and Pyroscope for profiles, and draws the results of queries as panels.

So Perses has two jobs. It stores **resources**: JSON or YAML documents such as projects, dashboards and datasources, each with a `kind`, a `metadata` block and a `spec`. And it runs **queries**: when a panel needs data, Perses forwards the panel's query to the right backend and returns the answer. The data itself never lives in Perses.

Perses is a sandbox project of the Cloud Native Computing Foundation (CNCF), the foundation that also hosts Kubernetes and Prometheus. Sandbox is the first of the three CNCF maturity levels, before incubating and graduated. Perses is also still before version 1.0, so field names and command flags can change between minor releases; this course uses v0.54.0 throughout.

## The open specification

Many dashboard tools store dashboards in their own format, and a dashboard only works in the tool that made it. Perses publishes its dashboard format as an open specification: a written definition of what a dashboard document contains. The Perses server uses it, but so can any other tool.

The specification exists in three languages: Go, CUE (a data language for schemas and configuration) and TypeScript. That is what makes dashboard-as-code possible. You can write a dashboard in CUE or Go, generate the JSON, check it with `percli lint`, and apply it to any server that understands the specification. A tool that produces dashboards `percli` can validate is, in the project's own words, compatible with Perses.

## The server and the embedded packages

You can use Perses in two ways, and they share the same specification.

| Use | What runs | Who it is for |
| --- | --- | --- |
| Perses server | The `perses` binary or container: a REST API, a database for resources, the datasource proxy and a web user interface | Teams who want a dashboard product to run |
| Embedded packages | npm packages such as `@perses-dev/components`, `@perses-dev/plugin-system` and `@perses-dev/dashboards`, used inside your own React application | Teams who build their own web application and want Perses panels in it |

This course works with the server. The embedded packages draw the same panels from the same dashboard documents, but your application provides the page around them.

Both ways rely on **plugins**. A plugin is the code that provides one type of panel, datasource, query, variable or explorer view: `TimeSeriesChart` draws a line chart, `PrometheusDatasource` describes how to reach Prometheus, and `PrometheusTimeSeriesQuery` holds a query in the Prometheus query language (PromQL). Every plugin has two halves: a CUE schema the server uses to check documents, and the user interface code that draws the plugin in the browser.

## A first look at the running server

Time to see the server. The playground runs Perses in the namespace `perses`. With the file database the Helm chart deploys it as a StatefulSet, so its single pod is called `perses-0`.

<!-- astrona:playground:renew -->

List the pods and the Service:

```sh
kubectl -n perses get statefulset,pods,service
```

You see one StatefulSet `perses`, the pod `perses-0` with the status `Running`, and the Service `perses` on port `8080`. That one pod holds the REST API, the datasource proxy, the web user interface and the database.

Make sure the port-forward from the landing page runs in a second terminal, then ask the server whether it is healthy:

```sh
curl -s http://perses.localtest.me:8080/api/v1/health
```

The response is a small JSON document from the health endpoint, the same one Kubernetes uses for the pod's readiness probe. Next, list the plugins this server knows:

```sh
curl -s http://perses.localtest.me:8080/api/v1/plugins | jq -r '.[].spec.plugins[] | "\(.kind) \(.spec.name)"'
```

Each line names a plugin type and a plugin, for example a `Panel` called `TimeSeriesChart` and a `Datasource` called `PrometheusDatasource`. Every dashboard you apply must use plugins from this list, because the server checks each document against the plugins' schemas.

Now do the same through `percli`. First point it at the server:

```sh
percli login http://perses.localtest.me:8080
```

Authentication is off in this playground, so the URL is all `percli` needs. It saves the URL in its configuration file, `~/.perses/config.json` on your machine, and every later command uses it. List the projects:

```sh
percli get project
```

The list is empty: a fresh server has no projects, dashboards or datasources. You can also open `http://perses.localtest.me:8080` in a browser to see the same empty home page.

You now know what Perses is: a server that stores dashboard resources and forwards queries, built on an open specification that the embedded packages and other tools share. The server in front of you is empty, and the next question is what to put in it first.

## Common pitfalls

> [!WARNING]
> - **Expecting Perses to store data.** Perses stores dashboards and datasource settings. If Prometheus loses its data, Perses has nothing to show.
> - **Forgetting the port-forward.** `percli` and `curl` on your machine reach Perses only while `kubectl port-forward` runs. A "connection refused" error usually means it stopped.
> - **Using a plugin the server does not know.** A dashboard that names a plugin missing from `/api/v1/plugins` is refused. Check the list before you write the document.
> - **Trusting a field name from another version.** Perses is before 1.0. A flag or field from an older blog post may not exist in v0.54.0.
