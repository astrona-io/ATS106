# Overview: Configure Perses With Its Helm Chart (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Perses and Prometheus, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, the Helm release `perses` with the `perses` chart 0.23.3: StatefulSet `perses`, pod `perses-0`, Service `perses` on port `8080`, and the ConfigMap `perses` with the configuration file. Authentication is off. The database is an `emptyDir`, so a restart deletes every resource that is not provisioned.
- **Prometheus v3.15.1** in the namespace `observability`, at `http://prometheus.observability:9090`.
- A **tester** pod in `observability` with `curl` and `jq`.
- **`percli` v0.54.0** and **Helm 3.22.1** on your machine, with the Helm repository `perses` already added.

Keep the port-forward running in a second terminal, and start it again after every restart of `perses-0`:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Helpers

Paste these once in each new terminal. `show_config` prints the configuration file Perses reads. `restart_perses` deletes the pod and waits for the new one.

```sh
show_config() { kubectl -n perses get configmap perses -o jsonpath='{.data.config\.yaml}'; echo; }
restart_perses() {
  kubectl -n perses delete pod perses-0
  kubectl -n perses rollout status statefulset/perses
}
```

Use them like this: `show_config`, `restart_perses`.

## Practice tasks

- Compare `helm -n perses get values perses` with `show_config`. Find one value that ended up in the file and one that did not.
- Turn read-only mode on with a values file, try `percli apply`, and look at the home page. Turn it off again.
- Set the home page message with an environment variable instead of the file, through the chart's `envVars` value (`PERSES_FRONTEND_INFORMATION`). Check which one wins when both are set.
- Provision a project from a ConfigMap. Mount it at a path that does not match `config.provisioning.folders`, and predict what happens before you look.
- Change a provisioned datasource through the API and time how long it takes to come back. Then change the interval and time it again.
- Try the chart's `datasources` value instead of your own ConfigMap, and find the folder you must add to `config.provisioning.folders`.
