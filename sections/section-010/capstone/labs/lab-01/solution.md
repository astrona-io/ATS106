# Solution: Untangle Datasources Across Three Scopes

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the global datasource, the `inventory` datasource, the dashboard scope of `incident-overview`, and that no dashboard was re-created.

## Step 1: Find every `prometheus`

With the port-forward running, log in and list the datasources at both resource scopes:

```sh
percli login http://perses.localtest.me:8080
percli get globaldatasources
percli get datasources --all
```

There is a global `prometheus` and an `inventory` `prometheus`. `billing` has none of its own. The third scope lives inside dashboards, so look there too:

```sh
percli describe dashboard incident-overview --project inventory -ojson | jq '.spec.datasources'
percli describe dashboard cost-overview --project billing -ojson | jq '.spec.datasources'
```

`incident-overview` carries its own `prometheus` under `spec.datasources`. `cost-overview` has none.

## Step 2: Work out which one each dashboard uses

The smallest scope that defines the name wins:

| Dashboard | Dashboard scope | Project scope | Global scope | Used |
| --- | --- | --- | --- | --- |
| `incident-overview` | yes | yes | yes | its own, dashboard-scoped one |
| `cost-overview` | no | no (`billing` has none) | yes | the global one |

So fixing only the global datasource would fix `billing` and leave `inventory` broken.

## Step 3: Test and fix the global datasource

Test it through the proxy:

```sh
curl -s -X POST --data-urlencode 'query=up' \
  http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query | jq .status
percli describe globaldatasource prometheus
```

The query fails, and the URL ends in port `9091`. Export it, change the URL to `http://prometheus.observability:9090`, and apply it:

```sh
percli describe globaldatasource prometheus -oyaml > globaldatasource-prometheus.yaml
percli apply -f globaldatasource-prometheus.yaml
```

Run the `curl` command again: `status` is now `success`. `cost-overview` shows data from now on.

## Step 4: Fix the project datasource in `inventory`

```sh
percli project inventory
percli describe datasource prometheus
```

Its URL is `http://prometheus.monitoring:9090`: the right port, but a namespace where no Prometheus runs. Export it, change the URL to `http://prometheus.observability:9090`, and apply it:

```sh
percli describe datasource prometheus -oyaml > datasource-prometheus.yaml
percli apply -f datasource-prometheus.yaml
curl -s -X POST --data-urlencode 'query=up' \
  http://perses.localtest.me:8080/proxy/projects/inventory/datasources/prometheus/api/v1/query | jq .status
```

## Step 5: Remove the dashboard-scoped override

The dashboard-scoped `prometheus` in `incident-overview` uses `directUrl: http://localhost:9090`. A direct URL means the browser calls the backend itself, and `localhost` in the reader's browser is not Prometheus. Because it is the smallest scope, it hides the project datasource you just fixed. Remove it and keep everything else:

```sh
percli describe dashboard incident-overview -ojson | jq 'del(.spec.datasources)' > dashboard-incident-overview.json
percli apply -f dashboard-incident-overview.json
```

The panel's query still names `prometheus`, and the lookup now stops at the project scope.

## Step 6: Check and submit

Open both dashboards in the browser: both panels draw data. Then submit:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Fix only the global datasource | `billing` works; `inventory` still uses its own broken definitions |
| Point the dashboard-scoped datasource at `http://prometheus.observability:9090` with `directUrl` | The browser still calls the backend itself and cannot reach an in-cluster address |
| Delete the project datasource in `inventory` | The dashboard falls through to the global one; it works today, but the team loses its own definition |
| Re-create `incident-overview` from scratch | The grader sees a new creation time |
