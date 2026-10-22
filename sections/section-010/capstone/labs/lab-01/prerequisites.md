# Prerequisites

Before starting this capstone you should be able to:

- Read Perses resources with `percli get` and `percli describe`.
- Explain the global, project and dashboard scopes of a datasource.
- Update a resource with `percli apply`.

## What the environment gives you

The environment builds itself before the task begins. It takes a few minutes:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, installed with the `perses`
  Helm chart 0.23.3. The environment puts **Helm 3.22.1** and **`percli`
  v0.54.0** in `/usr/local/bin` or `~/.local/bin` on your machine.
- Perses answers at `http://perses.localtest.me:8080` inside the cluster. On
  your machine, run `kubectl -n perses port-forward svc/perses 8080:8080` in a
  second terminal to reach the same address. If the name does not resolve,
  add `127.0.0.1 perses.localtest.me` to `/etc/hosts`.
- **Prometheus v3.15.1** in the namespace `observability`, at
  `http://prometheus.observability:9090`.

## Working rules

- Everything is graded on the **final state**, so check your result at the end
  and leave the fix in place.
- Change one thing at a time and check again.
- Perses keeps its data in a folder inside the pod. Restarting the pod deletes
  every resource that is not provisioned from files.
