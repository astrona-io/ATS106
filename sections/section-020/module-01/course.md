# Configure Perses With Its Helm Chart

You create a project in Perses, restart the pod, and the project is gone. Or you try to save a dashboard and the server refuses. Both are configuration, not bugs, and both come from one file the server reads at start. On Kubernetes that file comes from the values you give the Helm chart, so fixing it means knowing all three layers.

Perses is an open-source dashboard server for observability data. It runs as one program, `perses`, that reads a YAML configuration file and environment variables at start. The `perses` Helm chart turns your values into that file, a ConfigMap, and a StatefulSet that runs the program.

The module has three parts. **Ways To Run Perses** compares the binary, the container image and the Helm chart, and finds the pieces the chart created. **The Configuration File** walks through the sections of the file, overrides with environment variables, and read-only mode. **Provisioning Resources At Start** loads resources from a folder when the server starts, mounts that folder from a ConfigMap, and shows why provisioned resources survive a restart; a graded lab follows it.

## Learning objectives

After this module you can:

- Run Perses as a binary or a container, and install it with the Helm chart.
- Find the StatefulSet, the ConfigMap with the configuration file and the Service the chart creates.
- Read the configuration file and name what its `security`, `database`, `provisioning` and `frontend` sections do.
- Override a configuration value with a `PERSES_` environment variable.
- Turn read-only mode on and off, and say what it blocks.
- Explain what a pod restart does to the file database on an `emptyDir`.
- Provision resources from a folder, and mount that folder from a ConfigMap with the chart values.

## Before you start

You need Kubernetes basics: namespaces, ConfigMaps, StatefulSets and the commands `kubectl get`, `kubectl delete` and `kubectl port-forward`. You need to know how to run `helm upgrade` with a values file. You should know that Perses stores resources such as projects and datasources, each a JSON or YAML document with `kind`, `metadata` and `spec`.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** in the namespace `perses`, installed as the Helm release `perses` with the `perses` chart 0.23.3. The chart's values for this course are in a file the playground used; the pages show every value you need. Authentication is off. **Prometheus v3.15.1** runs at `http://prometheus.observability:9090`. The playground also puts `percli` v0.54.0 and Helm 3.22.1 on your machine.

Perses answers at `http://perses.localtest.me:8080`. Keep this port-forward running in a second terminal while you work:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

The name `perses.localtest.me` is a public DNS name for `127.0.0.1`, your own machine. If your network blocks it, add `127.0.0.1 perses.localtest.me` to `/etc/hosts`. A pod restart also ends the port-forward: start it again after every restart.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
