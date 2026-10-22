# Solution: Provision A Project And A Global Datasource

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the mount matches a provisioning folder, both resources come back after a restart, and the global datasource returns data.

## Step 1: Look at what exists

```sh
kubectl -n perses get configmap perses-provisioning -o yaml
helm -n perses get values perses
```

The ConfigMap holds `project.json` and `globaldatasource.json`. The values have no `volumes`, no `volumeMounts` and no `provisioning` section, so nothing mounts the ConfigMap and Perses reads no folder of yours.

## Step 2: Keep the current values

Save the current values to a file, so the upgrade keeps them:

```sh
helm -n perses get values perses -o yaml > perses-values.yaml
```

## Step 3: Add the mount and the folder

Save this as `perses-values-provisioning.yaml`:

```yaml
config:
  provisioning:
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

Apply both files to the release:

```sh
helm -n perses upgrade perses perses/perses --version 0.23.3 \
  -f perses-values.yaml -f perses-values-provisioning.yaml --wait
```

The three settings name the same path: the ConfigMap becomes a volume, the volume is mounted at `/etc/perses/provisioning-files`, and Perses reads that folder.

## Step 4: Prove it survives a restart

Delete the pod, wait for the new one, and start the port-forward again in a second terminal:

```sh
kubectl -n perses delete pod perses-0
kubectl -n perses rollout status statefulset/perses
```

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

Then list the resources and send a query through the global datasource:

```sh
percli login http://perses.localtest.me:8080
percli get project
percli get globaldatasources
curl -s -X POST --data-urlencode 'query=up' \
  http://perses.localtest.me:8080/proxy/globaldatasources/prometheus-global/api/v1/query | jq .status
```

`inventory` and `prometheus-global` are there on an empty database, and the query returns `success`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create the project and the datasource with `percli apply` | They exist until the grader restarts the pod, then they are gone |
| `helm upgrade` with only the new file | Helm resets every other value to the chart default, including the image version and the database settings |