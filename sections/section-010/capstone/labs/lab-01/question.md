# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Datasource scopes in Perses

## Scenario

Two teams share one Perses server. The `inventory` team has the dashboard `incident-overview`, and the `billing` team has the dashboard `cost-overview`. Both panels query `up` from a datasource named `prometheus`, and both are empty.

A datasource named `prometheus` exists more than once on this server. Somebody changed things at several scopes while "fixing" the problem, and nobody knows which definition each dashboard uses now.

Perses answers at `http://perses.localtest.me:8080`. Start the port-forward in a second terminal first:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

Authentication is off. Prometheus runs at `http://prometheus.observability:9090`.

## Your task

1. Find every datasource named `prometheus` on the server, at every scope, and say which one each dashboard uses.
2. Make both dashboards show data, with every query going through the Perses proxy.
3. Keep the shared global datasource working, because other projects will use it.

## Constraints

- **Update the existing resources.** Do not delete and re-create either dashboard.
- A dashboard must not keep a datasource that the browser calls directly.
- Do not change Prometheus or the Perses installation.

## Done when

- A query for `up` through the global datasource `prometheus` returns data.
- A query for `up` through the `inventory` datasource `prometheus` returns data.
- `incident-overview` has no dashboard-scoped `prometheus` datasource that bypasses the proxy or points anywhere else.
- Both dashboards keep their original creation time.
