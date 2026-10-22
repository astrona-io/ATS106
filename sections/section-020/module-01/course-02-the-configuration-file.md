# The Configuration File

The Perses configuration file is short, but each of its sections changes what the server does: whether it accepts writes, where it stores resources, what it loads at start, and what the home page shows. On Kubernetes you change it through the Helm values, never inside the pod. This part reads the main sections, overrides one with an environment variable, and turns read-only mode on and off to see what it blocks.

## The sections of the file

The configuration file is YAML. Every section is optional, and a missing section means the defaults.

| Section | What it controls |
| --- | --- |
| `security` | `readonly`, `enable_auth`, the `encryption_key` for stored secrets, cookies, `authentication` providers and `authorization` |
| `database` | Where resources live: `file` (a folder and a file extension) or `sql` (a MySQL or MariaDB connection) |
| `provisioning` | Folders of resource files that Perses loads at start and again at an `interval` |
| `frontend` | The web user interface: `information` (Markdown on the home page), `important_dashboards`, `disable` |
| `plugin` | Where the server finds and loads its plugins |
| `api_prefix` | A path prefix for the API, for a server behind a reverse proxy |

The `encryption_key` deserves a note. Perses encrypts sensitive values it stores, such as a datasource password in a `Secret`, with this key. The key must be exactly 32 bytes. Without one, Perses uses a built-in default and logs a warning at start, which is acceptable in a lab and not on a real server.

## Environment variables override the file

Every key in the file also has an environment variable. The name is `PERSES_` followed by the path of the key in upper case, joined with underscores: `security.readonly` becomes `PERSES_SECURITY_READONLY`, and `database.file.extension` becomes `PERSES_DATABASE_FILE_EXTENSION`. For a list, the index is part of the name: `PERSES_PROVISIONING_FOLDERS_0`. An environment variable wins over the file.

The chart uses this for secrets. Its `envVars` value creates a Kubernetes Secret and passes each entry to the container as an environment variable, so a value such as an encryption key or a client secret never appears in the ConfigMap.

## Changing the configuration with Helm

You change the configuration by upgrading the release with new values. Start from the values this course installs with.

<!-- astrona:playground:renew -->

Save this as `perses-values.yaml`:

```yaml
fullnameOverride: perses
image:
  version: v0.54.0
service:
  type: ClusterIP
  port: 8080
config:
  security:
    readonly: false
    enable_auth: false
    cookie:
      same_site: lax
      secure: false
  database:
    file:
      folder: /perses
      extension: json
persistence:
  enabled: false
```

Now add a second file that changes two settings: a Markdown message for the home page, and read-only mode. Save this as `perses-values-readonly.yaml`:

```yaml
config:
  security:
    readonly: true
  frontend:
    information: |-
      # Inventory dashboards
      This server is read-only during the change freeze.
```

Apply both with Helm. Later files win, so the second file overrides `readonly`:

```sh
helm repo add perses https://perses.github.io/helm-charts
helm -n perses upgrade perses perses/perses --version 0.23.3 \
  -f perses-values.yaml -f perses-values-readonly.yaml --wait
```

The chart writes a new ConfigMap and, because the file changed, restarts the pod. Start the port-forward again, then check the result:

```sh
kubectl -n perses get configmap perses -o jsonpath='{.data.config\.yaml}' | grep -A1 readonly
echo '{"kind":"Project","metadata":{"name":"frozen"},"spec":{}}' | percli apply -f -
```

The ConfigMap shows `readonly: true`, and `percli apply` fails: in read-only mode the server refuses every `POST`, `PUT` and `DELETE` request. Open `http://perses.localtest.me:8080` in your browser. The home page shows your Markdown message, and the buttons to create or edit things are gone, because the user interface follows the same setting.

Turn read-only mode off again by upgrading with the base file only:

```sh
helm -n perses upgrade perses perses/perses --version 0.23.3 -f perses-values.yaml --wait
```

After the restart and a new port-forward, `percli apply` with the `frozen` project succeeds. Keep `perses-values.yaml`: every later change in this module starts from it.

You can now read the configuration file, override it with Helm values or environment variables, and use read-only mode. But every restart in this playground still empties the database, and the next step is to make some resources come back on their own.

## Common pitfalls

> [!WARNING]
> - **Editing the ConfigMap by hand.** The next `helm upgrade` overwrites it, and Perses only reads the file at start. Change the values instead.
> - **Forgetting `--version` or a values file in `helm upgrade`.** Without the base file, Helm falls back to the chart defaults for everything you left out.
> - **Leaving read-only mode on by mistake.** Every write fails, including `percli apply` and the user interface. Check `security.readonly` first when the server refuses all changes.
> - **Putting a secret into `config:`.** Values under `config:` end up in a ConfigMap in clear text. Pass secrets through `envVars`, which the chart stores in a Secret.
