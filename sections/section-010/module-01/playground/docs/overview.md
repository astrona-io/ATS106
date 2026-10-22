# Overview: Find Your Way Around Perses (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Perses and Prometheus, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses` (StatefulSet `perses`, pod `perses-0`, Service `perses` on port `8080`), installed with the `perses` Helm chart 0.23.3. Authentication is off. The database is a folder in the pod, so deleting `perses-0` deletes every resource.
- **Prometheus v3.15.1** in the namespace `observability`, at `http://prometheus.observability:9090`. It scrapes itself, so `up` always has data.
- A **tester** pod in `observability` with `curl` and `jq`, for requests from inside the cluster.
- **`percli` v0.54.0** and **Helm 3.22.1** on your machine.
- No projects yet.

Keep the port-forward running in a second terminal, so `http://perses.localtest.me:8080` answers on your machine:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Helpers

Paste these once in each new terminal. `proxy_query` sends a PromQL query through a Perses datasource proxy path and prints the status and the number of series. `inside_cluster` runs a command in the tester pod.

```sh
proxy_query() {
  curl -s -X POST --data-urlencode "query=$2" "http://perses.localtest.me:8080$1/api/v1/query" \
    | jq '{status: .status, series: (.data.result | length)}'
}
inside_cluster() { kubectl -n observability exec -i deploy/tester -- "$@"; }
```

Use them like this: `proxy_query /proxy/projects/inventory/datasources/prometheus up`, `inside_cluster curl -s http://perses.localtest.me:8080/api/v1/health`.

## Practice tasks

- Create the project `inventory`, a project datasource `prometheus` and a dashboard with one `TimeSeriesChart` panel. Open the dashboard in the browser.
- Create a `GlobalDatasource` named `prometheus` that points at port `9091`. Predict whether the dashboard in `inventory` still shows data, then check.
- Add a dashboard-scoped datasource under `spec.datasources` of your dashboard with the same name and a wrong URL. Predict which datasource the panel uses now.
- Change a query's datasource name to one that does not exist and apply the dashboard. Note that the apply succeeds, and find the error in the browser.
- Misspell the panel plugin kind (for example `TimeSeriesChrat`) and apply. Compare the response with the previous task.
- Run `percli describe dashboard scrape-health -ojson` and find `createdAt`. Apply the file again and check that `createdAt` stays the same while `updatedAt` changes.
- Delete the pod `perses-0`, wait for it to come back, and run `percli get project`. Explain what you see.
