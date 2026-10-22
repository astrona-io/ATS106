# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Perses resources and the datasource proxy

## Scenario

The project `inventory` has a datasource `prometheus` and a dashboard `service-overview` with one panel that shows the metric `up`. The dashboard applied without an error, yet its panel shows no data.

Perses answers at `http://perses.localtest.me:8080`. Start the port-forward in a second terminal first:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

Authentication is off.

## Your task

In the project `inventory`:

1. Find every reason the panel of `service-overview` gets no data.
2. Fix the datasource `prometheus` so it reaches Prometheus at `http://prometheus.observability:9090`.
3. Fix the dashboard so its query uses a datasource that exists.

## Constraints

- **Update the existing resources.** Do not delete and re-create the datasource or the dashboard.
- Keep the panel's query `up`. Fix the reference, not the query.
- Do not change Prometheus or the Perses installation.

## Done when

- A query for `up` through `/proxy/projects/inventory/datasources/prometheus` returns data.
- Every query in `service-overview` names a datasource that exists, and the panel still queries `up`.
- Both resources keep their original creation time.
