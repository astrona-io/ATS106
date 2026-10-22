# Ways To Run Perses

Perses is one program, but you can start it in several ways, and each way hides the same configuration in a different place. Before you change a setting, you need to know how your server was started and where its settings come from. This part compares the binary, the container image and the Helm chart, then finds every piece the chart created in the playground.

## One program, three ways to start it

Every Perses release on GitHub ships an archive per platform. It holds two programs, `perses` (the server) and `percli` (the command-line tool), a sample `config.yaml`, and the core plugins as archives. You start the server with a configuration file:

```sh
./perses --config=./config.yaml
```

The server listens on port `8080` by default, serves its REST API under `/api`, serves the web user interface, and exposes its own metrics at `/metrics`. The flag `--web.listen-address` changes the port, and `--web.tls-cert-file` with `--web.tls-key-file` turns on HTTPS.

The container image `persesdev/perses` holds the same programs and the plugins. A tag names a version, such as `persesdev/perses:v0.54.0`. The default tags are distroless: the image holds no shell, so you cannot run `sh` or `cat` inside it. The `-debug` tags add a shell for troubleshooting. A container starts like this with Docker or Podman:

```sh
docker run --name perses --rm -p 127.0.0.1:8080:8080 persesdev/perses:v0.54.0
```

With no configuration file, the server uses its defaults: no authentication, a file database inside the container, and a default encryption key. It logs a warning about that key at start. For a quick look this is fine, but a container started this way loses everything when it stops.

The Helm chart `perses` is the third way, and the one this course uses. It runs the same image on Kubernetes and builds the configuration file from your values.

## What the chart created

The chart picks the kind of workload from the database you choose. With the file database, Perses keeps every resource as a file in a folder, so the chart runs a StatefulSet with one pod. With an SQL database (MySQL or MariaDB), the data lives outside the pod, and the chart runs a Deployment.

<!-- astrona:playground:renew -->

List what the release `perses` created:

```sh
kubectl -n perses get statefulset,pod,service,configmap
```

You see the StatefulSet `perses` with the pod `perses-0`, the Service `perses` on port `8080`, and a ConfigMap `perses`. The ConfigMap holds the configuration file the server reads at start. Print it:

```sh
kubectl -n perses get configmap perses -o jsonpath='{.data.config\.yaml}'
```

The file has sections such as `security`, `database` and `provisioning`. The `database` section names the file database and its folder, `/perses`. Because the image is distroless, reading the ConfigMap is the reliable way to see the configuration; `kubectl exec` into the pod has no shell to run.

Helm keeps the values you gave it. Compare them with the file:

```sh
helm -n perses get values perses
```

These are the values the playground installed with. Every key under `config:` in the values became a key in the configuration file. The other values, such as `image.version` and `persistence`, shaped the StatefulSet instead.

## The database and a restart

The values set `persistence.enabled: false`. With persistence off, the chart mounts an `emptyDir` volume at `/perses`, the database folder. An `emptyDir` is created empty when the pod starts and deleted when the pod goes away. So in this playground, restarting the pod deletes every resource.

See it happen. Create a project, restart the pod, and look again:

```sh
percli login http://perses.localtest.me:8080
echo '{"kind":"Project","metadata":{"name":"scratch"},"spec":{}}' | percli apply -f -
kubectl -n perses delete pod perses-0
kubectl -n perses rollout status statefulset/perses
```

Start the port-forward again in your second terminal, because the old one ended with the pod. Then list the projects:

```sh
percli get project
```

`scratch` is gone. The new pod started with an empty database folder. With `persistence.enabled: true`, the chart would create a PersistentVolumeClaim for `/perses` instead, and the project would survive. An SQL database survives too, because it lives outside the pod.

You now know how the server in your playground was started and where its configuration lives: the values in Helm, the file in the ConfigMap, and the database in an `emptyDir`. The open question is what the sections of that file control, and how to change them safely.

## Common pitfalls

> [!WARNING]
> - **Running `kubectl exec ... -- sh` in the Perses pod.** The default image is distroless and has no shell. Read the ConfigMap, or use a `-debug` image for troubleshooting.
> - **Expecting data to survive a restart.** With the file database on an `emptyDir`, a new pod starts empty. Use persistence, an SQL database, or provisioning.
> - **Looking for a Deployment.** With the file database the chart creates a StatefulSet; with an SQL database it creates a Deployment.
> - **Forgetting the port-forward after a restart.** The port-forward ends with the pod it was connected to. Start it again.
