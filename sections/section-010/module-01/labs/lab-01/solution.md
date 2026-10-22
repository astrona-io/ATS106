# Solution: Repair A Datasource And The Dashboard That Uses It

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the datasource URL, a query through the proxy, the dashboard's datasource reference, and that neither resource was re-created.

## Step 1: Point percli at the server and the project

With the port-forward running, log in and select the project:

```sh
percli login http://perses.localtest.me:8080
percli project inventory
percli get datasources
percli get dashboards
```

The project has one datasource, `prometheus`, and one dashboard, `service-overview`.

## Step 2: Test the datasource on its own

Send the panel's query through the datasource proxy:

```sh
curl -s -X POST --data-urlencode 'query=up' \
  http://perses.localtest.me:8080/proxy/projects/inventory/datasources/prometheus/api/v1/query
```

Perses answers with an error instead of a Prometheus result, so the datasource cannot reach its backend. Read its URL:

```sh
percli describe datasource prometheus
```

The `url` under `proxy.spec` ends in port `9091`. Prometheus listens on `9090`.

## Step 3: Fix the datasource in place

Save the current definition, change the port, and apply it again. Export it to a file:

```sh
percli describe datasource prometheus -oyaml > datasource-prometheus.yaml
```

Edit `datasource-prometheus.yaml` and change the URL to `http://prometheus.observability:9090`. You may delete the `createdAt` and `updatedAt` lines; the server keeps its own values. Apply it:

```sh
percli apply -f datasource-prometheus.yaml
```

Run the `curl` command from step 2 again. This time `status` is `success` and the result holds at least one series.

## Step 4: Read the dashboard's datasource reference

The datasource works, but the panel can still be empty. Look at what the query names:

```sh
percli describe dashboard service-overview -ojson \
  | jq '.spec.panels[].spec.queries[].spec.plugin.spec.datasource'
```

The query names a datasource called `prom`. No datasource of that name exists in `inventory` or globally, so Perses has nowhere to send the query.

## Step 5: Fix the reference in place

Export the dashboard, change only the datasource name, and apply it:

```sh
percli describe dashboard service-overview -ojson \
  | jq '(.spec.panels[].spec.queries[].spec.plugin.spec.datasource.name) |= "prometheus"' \
  > dashboard-service-overview.json
percli apply -f dashboard-service-overview.json
```

The query text stays `up`; only the datasource name changes.

## Step 6: Check the result and submit

Open the dashboard in the browser: the panel now draws data. Confirm that both resources were updated, not re-created:

```sh
percli describe datasource prometheus -ojson | jq '.metadata.createdAt'
percli describe dashboard service-overview -ojson | jq '.metadata.createdAt'
```

Then send the lab for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the dashboard and create a new one | The panel works, but the grader sees a new creation time; anyone who bookmarked or edited it loses that history |
| Create a datasource called `prom` | The reference resolves, but now two datasources describe the same backend, and the broken name stays in the dashboard |
| Change the query instead of the reference | The panel shows something else; the task is to restore the original panel |

## Practice on your own

- Add a `GlobalDatasource` called `prom` that points at Prometheus and undo the reference fix. Explain why the panel works again.
- Run `percli lint -f dashboard-service-overview.json` with and without `--online`, and compare what each one reports.
