# Provisioning Resources At Start

A Perses server whose database lives in an `emptyDir` forgets everything on every restart. Even with a persistent database, you often want some resources, such as a shared datasource or a project for every team, to exist on every server without anyone creating them by hand. Provisioning does that: Perses reads resource files from folders when it starts, and again at a fixed interval. This part provisions a project and a datasource from a Kubernetes ConfigMap and proves that they survive a restart.

## How provisioning works

The `provisioning` section of the configuration file lists folders and an interval:

```yaml
provisioning:
  interval: 10m
  folders:
    - /etc/perses/provisioning-files
```

When the server starts, it walks every listed folder, including sub-folders, reads every JSON or YAML file that holds a Perses resource, and writes each resource into its database. A file may hold one resource or a list of resources. Files Perses does not understand are ignored. After that, it does the same again at every `interval`. The Perses documentation gives one hour as the default; the Helm chart's values set `10m`.

There is one rule to keep in mind: **a provisioned resource overwrites what is in the database**. If someone changes a provisioned datasource through the API or the user interface, the next provisioning run puts the file's version back. So the file is the source of truth, and a change to a provisioned resource belongs in the file.

## Getting files into the pod

The files must be inside the Perses container. On Kubernetes, the natural place for them is a ConfigMap, mounted as a folder. The chart gives you three ways to do that:

| Way | Values | When it fits |
| --- | --- | --- |
| Mount your own ConfigMap | `volumes`, `volumeMounts` and `config.provisioning.folders` | A fixed set of files you manage next to the release |
| The chart's `datasources` value | A list of datasource resources; the chart makes a ConfigMap and mounts it at `/etc/perses/datasources` | Datasources only; the folder must still be added to `config.provisioning.folders` |
| The ConfigMap sidecar | `sidecar.enabled: true`; a `k8s-sidecar` container copies every ConfigMap with the label `perses.dev/resource: "true"` into the first provisioning folder | Many teams adding their own ConfigMaps, possibly from other namespaces |

This part uses the first way, because it shows every moving piece.

<!-- astrona:playground:renew -->

The commands below need the file `perses-values.yaml` with the values this course installs with. If you do not have it, save it again: it sets `fullnameOverride: perses`, `image.version: v0.54.0`, the Service on port `8080`, `security.readonly: false`, `security.enable_auth: false`, the file database at `/perses` with the extension `json`, and `persistence.enabled: false`.

First, the resources. Save this as `configmap-perses-provisioning.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: perses-provisioning
  namespace: perses
data:
  project-reports.json: |
    {"kind": "Project", "metadata": {"name": "reports"}, "spec": {}}
  datasource-reports.json: |
    {"kind": "Datasource", "metadata": {"name": "prometheus", "project": "reports"}, "spec": {"default": true, "plugin": {"kind": "PrometheusDatasource", "spec": {"proxy": {"kind": "HTTPProxy", "spec": {"url": "http://prometheus.observability:9090"}}}}}}
```

Apply it:

```sh
kubectl apply -f configmap-perses-provisioning.yaml
```

The ConfigMap exists, but Perses does not know about it yet. Now the values that mount it and add the folder. Save this as `perses-values-provisioning.yaml`:

```yaml
config:
  provisioning:
    interval: 1m
    folders:
      - /etc/perses/provisioning-files
volumes:
  - name: provisioning-files
    configMap:
      name: perses-provisioning
volumeMounts:
  - name: provisioning-files
    mountPath: /etc/perses/provisioning-files
    readOnly: true
```

Apply both values files:

```sh
helm -n perses upgrade perses perses/perses --version 0.23.3 \
  -f perses-values.yaml -f perses-values-provisioning.yaml --wait
```

Then check the result, after you start the port-forward again:

```sh
percli login http://perses.localtest.me:8080
percli get project
percli get datasources --project reports
```

The project `reports` and its datasource exist, though nobody created them through the API. The `volumes` entry tells Kubernetes to turn the ConfigMap into a volume, the `volumeMounts` entry puts that volume at `/etc/perses/provisioning-files` in the `perses` container, and the folder in `config.provisioning.folders` tells Perses to read it. All three must name the same path.

## Provisioned resources survive a restart

Now the proof. Delete the pod, which empties the database folder:

```sh
kubectl -n perses delete pod perses-0
kubectl -n perses rollout status statefulset/perses
```

Start the port-forward again and list the projects:

```sh
percli get project
```

`reports` is back. The new pod started with an empty database, and provisioning wrote the files into it at start. A project you created by hand, without a file, would be gone.

Finally, see the overwrite rule. Change the datasource of `reports` through the API, so that it points at port `9091`, and wait a little over one minute, the interval you set:

```sh
percli describe datasource prometheus --project reports -ojson \
  | jq '.spec.plugin.spec.proxy.spec.url = "http://prometheus.observability:9091"' | percli apply -f -
sleep 75
percli describe datasource prometheus --project reports -ojson | jq -r '.spec.plugin.spec.proxy.spec.url'
```

The URL is back on port `9090`. The provisioning run replaced your change with the file's version. To change a provisioned resource for good, change the ConfigMap.

You can now provision resources from a ConfigMap with three matching settings, and you know that the file, not the database, decides what a provisioned resource looks like. That is the skill the lab asks for.

## Common pitfalls

> [!WARNING]
> - **Mounting the ConfigMap at one path and listing another.** The `mountPath` and the folder in `config.provisioning.folders` must be the same path, letter for letter.
> - **Fixing a provisioned resource through the API.** The next provisioning run overwrites it. Change the file.
> - **Expecting a ConfigMap change at once.** Kubernetes updates a mounted ConfigMap after a short delay, and Perses reads it at the next interval. A restart reads it at start.
> - **Listing only `/etc/perses/datasources` or only your folder.** Setting `config.provisioning.folders` replaces the chart's default list; name every folder you need.

## Your mission: Provision A Project And A Global Datasource

You can now mount a ConfigMap of resources into Perses through the chart values and make Perses read it. The lab gives you a ConfigMap with a project and a global datasource that Perses ignores, and asks you to provision both so they survive a restart.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-106-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS106.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-106-lab-020-01
astrona start ats-106-playground-020-01
```
