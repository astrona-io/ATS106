# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Perses configuration and provisioning

## Scenario

Before a change freeze, somebody upgraded the Perses release `perses` in a hurry. Since then:

- every attempt to create or change anything in Perses fails, from `percli` and from the web user interface;
- the project `inventory` and the `GlobalDatasource` `prometheus-global`, which should be provisioned from the ConfigMap `perses-provisioning`, never appear;
- the team says that even when the global datasource existed, its panels showed no data.

The freeze is over. Perses is the Helm release `perses` in the namespace `perses`, chart `perses/perses` version `0.23.3`. Prometheus runs at `http://prometheus.observability:9090`.

## Your task

1. Find every reason for the three problems.
2. Fix them so Perses accepts changes again, provisions both resources from the ConfigMap, and the global datasource returns data.

## Constraints

- Change the installation only with `helm upgrade` on the release `perses`. Keep the values that are correct.
- Fix the provisioned files at their source, the ConfigMap. A change made only through the API is overwritten by the next provisioning run, and the grader restarts Perses.
- Do not switch to a different database or turn on persistence.

## Done when

- Perses accepts a new project.
- The ConfigMap is mounted in the `perses` container at a path that is listed in `config.provisioning.folders`.
- The file for `prometheus-global` in the ConfigMap points at `http://prometheus.observability:9090`.
- After the pod `perses-0` restarts, `inventory` and `prometheus-global` exist, and a query for `up` through `/proxy/globaldatasources/prometheus-global` returns data.
