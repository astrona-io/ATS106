# Summary

Perses is one program, `perses`, that reads a YAML configuration file and environment variables at start. You can run it from the release archive, as the container image `persesdev/perses`, or on Kubernetes with the `perses` Helm chart. The default image is distroless and has no shell. The chart writes the configuration file into a ConfigMap from your values, and it runs a StatefulSet when the database is a folder of files and a Deployment when it is an SQL database.

## What you learned

The configuration file has a few sections. `security` holds read-only mode, authentication, authorization and the 32-byte encryption key. `database` chooses between a file folder and MySQL or MariaDB, `provisioning` lists folders to load at an interval, and `frontend` shapes the web user interface. Every key has an environment variable named `PERSES_` plus its path in upper case, and the variable wins over the file. The chart's `envVars` value passes such variables through a Kubernetes Secret, which is the place for secrets.

You change the configuration with `helm upgrade` and values files, later files winning, and the chart restarts the pod when the file changes. Read-only mode makes the server refuse every `POST`, `PUT` and `DELETE`, and the user interface hides its edit buttons to match.

With the file database on an `emptyDir`, a restart deletes every resource. Provisioning brings resources back: Perses reads every resource file in the listed folders at start and at each interval, and a provisioned file always overwrites the database's version. To provision from a ConfigMap, the chart needs three matching settings. The key facts to remember are these:

- A `volumes` entry turns the ConfigMap into a volume.
- A `volumeMounts` entry places it at a path in the `perses` container.
- `config.provisioning.folders` must list exactly that path.
- A change to a provisioned resource belongs in its file, not in the API.

<!-- astrona:playground:destroy -->
