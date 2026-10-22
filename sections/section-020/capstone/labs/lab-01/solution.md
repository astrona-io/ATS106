# Solution: Make A Perses Install Writable And Restart-Safe

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: a write succeeds, the mount matches a provisioning folder, the ConfigMap has the right URL, both resources survive a restart, and the global datasource returns data.

## Step 1: Read the values and the configuration file

```sh
helm -n perses get values perses
kubectl -n perses get configmap perses -o jsonpath='{.data.config\.yaml}'
```

Two things stand out. `security.readonly` is `true`, which explains why every change fails. The provisioning folder is `/etc/perses/provisioning-files`, but the `volumeMounts` entry mounts the ConfigMap at `/etc/perses/provisoning-files`, with a letter missing. Perses reads an empty folder, so nothing is provisioned.

## Step 2: Read the provisioned files

```sh
kubectl -n perses get configmap perses-provisioning -o jsonpath='{.data.globaldatasource\.json}'; echo
```

The global datasource points at `http://prometheus.observability:9091`. Prometheus listens on `9090`, so even a provisioned `prometheus-global` would return no data.

## Step 3: Fix the file at its source

Change the port in the ConfigMap. Export it, edit it, and apply it:

```sh
kubectl -n perses get configmap perses-provisioning -o yaml > configmap-perses-provisioning.yaml
```

In `configmap-perses-provisioning.yaml`, change `9091` to `9090` in `globaldatasource.json`. Apply it:

```sh
kubectl apply -f configmap-perses-provisioning.yaml
```

## Step 4: Fix the values

Save the current values, then add a file that corrects both mistakes:

```sh
helm -n perses get values perses -o yaml > perses-values-current.yaml
```

Save this as `perses-values-fixed.yaml`:

```yaml
config:
  security:
    readonly: false
volumeMounts:
  - name: provisioning-files
    mountPath: /etc/perses/provisioning-files
    readOnly: true
```

Apply both, the fix last so it wins:

```sh
helm -n perses upgrade perses perses/perses --version 0.23.3 \
  -f perses-values-current.yaml -f perses-values-fixed.yaml --wait
```

Helm replaces lists as a whole, so the new `volumeMounts` list replaces the broken one. The `volumes` entry and `config.provisioning.folders` were already correct.

## Step 5: Restart and check

Restart the pod so it starts with an empty database and provisions from the folder, then start the port-forward again in a second terminal:

```sh
kubectl -n perses delete pod perses-0
kubectl -n perses rollout status statefulset/perses
```

```sh
percli login http://perses.localtest.me:8080
percli get project
echo '{"kind":"Project","metadata":{"name":"after-freeze"},"spec":{}}' | percli apply -f -
curl -s -X POST --data-urlencode 'query=up' \
  http://perses.localtest.me:8080/proxy/globaldatasources/prometheus-global/api/v1/query | jq .status
```

`inventory` is back, the new project is accepted, and the query returns `success`. Delete the test project with `percli delete project after-freeze` if you like.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Fix `prometheus-global` with `percli apply` | The next provisioning run, or the grader's restart, puts the file's port `9091` back |
| Change `config.provisioning.folders` to the misspelled path | It works, but the folder name keeps its typo; the grader accepts it, and the next person still trips over it |
| Turn on persistence so resources survive | The resources survive, but the wrong URL and the missing provisioning stay, and the task forbids it |
