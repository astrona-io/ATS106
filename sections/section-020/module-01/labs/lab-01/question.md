# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Perses configuration and provisioning

## Scenario

The platform team keeps a ConfigMap `perses-provisioning` in the namespace `perses`. It holds two resource files: the project `inventory` and the `GlobalDatasource` `prometheus-global`, which points at Prometheus. Perses keeps its database in an `emptyDir`, so after every restart the server is empty, and the team wants these two resources to be there every time.

Perses is the Helm release `perses` in the namespace `perses`, installed with the chart `perses/perses` version `0.23.3`. Read its current values with `helm -n perses get values perses`; the Helm repository `perses` is already added on your machine.

## Your task

1. Make Perses load the files in the ConfigMap `perses-provisioning` at start, through the Helm release's values.
2. Prove that the project and the global datasource come back after the Perses pod restarts.

## Constraints

- Change the installation only with `helm upgrade` on the release `perses`. Keep every value it already has.
- Do not change the files in the ConfigMap.
- Do not create the resources through the API or `percli` as a substitute: the grader restarts Perses.

## Done when

- The ConfigMap is mounted in the `perses` container at a path that is listed in `config.provisioning.folders`.
- After the pod `perses-0` restarts, the project `inventory` and the `GlobalDatasource` `prometheus-global` exist.
- A query for `up` through `/proxy/globaldatasources/prometheus-global` returns data.
