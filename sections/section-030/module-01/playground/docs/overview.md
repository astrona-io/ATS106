# Overview: Secure Perses And Work With percli (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Perses and Prometheus, creates two projects, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, the Helm release `perses` with the chart 0.23.3 (pod `perses-0`, Service `perses` on port `8080`). **Authentication is off.** The database is an `emptyDir`, so a restart deletes every resource that is not provisioned.
- The projects **`inventory`** and **`billing`**, each with a datasource `prometheus` that points at `http://prometheus.observability:9090`.
- **Prometheus v3.15.1** in the namespace `observability`, and a **tester** pod there with `curl` and `jq`.
- **`percli` v0.54.0** and **Helm 3.22.1** on your machine, with the Helm repository `perses` already added.

Keep the port-forward running in a second terminal, and start it again after every restart of `perses-0`:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Helpers

Paste these once in each new terminal. `login_as` logs `percli` in as a user. `can_create_dashboard` tries to create a small dashboard in a project as the current `percli` user and prints whether it worked, then removes it again.

```sh
login_as() { percli login http://perses.localtest.me:8080 --username "$1" --password "$2"; }
can_create_dashboard() {
  printf '%s' '{"kind":"Dashboard","metadata":{"name":"probe"},"spec":{"duration":"1h","panels":{"up":{"kind":"Panel","spec":{"display":{"name":"up"},"plugin":{"kind":"TimeSeriesChart","spec":{}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"up"}}}}]}}},"layouts":[{"kind":"Grid","spec":{"items":[{"x":0,"y":0,"width":12,"height":6,"content":{"$ref":"#/spec/panels/up"}}]}}]}}' \
    | percli apply -f - --project "$1" && echo "allowed in $1" && percli delete dashboard probe --project "$1"
}
```

Use them like this: `login_as dana dana-password`, `can_create_dashboard inventory`. They need authentication on, with the users from the module.

## Practice tasks

- Find `~/.perses/config.json` and read it before and after you turn on authentication.
- List every datasource on the server with one `percli get` command, as a table and as JSON.
- Break a dashboard file on purpose and compare `percli lint` with and without `--online`.
- Turn on authentication without provisioning an administrator. Explain what you can and cannot do, then fix it.
- Give `dana` a `Role` that may update dashboards but not create them. Check both actions as `dana`.
- Try to change the role of an existing `RoleBinding` with `percli apply`, and read the error.
- Leave sign-up on and create a user with an anonymous `POST` to `/api/v1/users`. Then turn sign-up off and try again.
