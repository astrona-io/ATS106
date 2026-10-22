# Working With percli

Clicking through the web user interface is fine for one dashboard. For ten, for a review in Git, or for a script, you need the command line. `percli` is the Perses command-line tool: every command it runs is a call to the Perses REST API. This part covers the commands you use every day, where `percli` keeps its settings, and how to check a file before you apply it.

## Logging in and the configuration file

`percli` needs to know which server to talk to. `percli login` stores that, together with a token when the server needs one.

<!-- astrona:playground:renew -->

With the port-forward running, log in. Authentication is off in this playground, so the URL is enough:

```sh
percli login http://perses.localtest.me:8080
```

`percli` saves the URL in its configuration file, `~/.perses/config.json` in your home folder. Look at it:

```sh
jq . ~/.perses/config.json
```

The file holds the server URL and, once you select one, the project. When the server requires a login, it also holds the access token, which is why you should treat this file like a password. The global flag `--percliconfig` points `percli` at another file, which is handy when you work with two servers.

`percli whoami` prints which user the current session uses. With authentication off there is no user to show; you will run it again once authentication is on.

## Projects and listing resources

Most resources belong to a project, so `percli` works with one selected project. Select `inventory` and list what is in it:

```sh
percli project inventory
percli get datasources
percli get datasources --all
```

The first `get` lists the datasources of `inventory`. With `--all` (or `-a`), `percli` lists them across every project, and the `PROJECT` column shows where each one lives. `--project billing` (or `-p billing`) picks another project for one command without changing the selection.

`percli get` prints a table. For scripts, ask for JSON or YAML and read it with `jq`:

```sh
percli get datasources --all -ojson | jq -r '.[] | "\(.metadata.project) \(.metadata.name) \(.spec.plugin.spec.proxy.spec.url)"'
```

Each line shows a project, a datasource name and the URL it points at. The same `-o` flag works with `percli describe`, which prints one full resource.

## Apply, describe and delete

`percli apply` creates a resource that does not exist and updates one that does. It reads a file with `-f`, standard input with `-f -`, or every file in a folder with `-d`. A quick way to change one field is to describe the resource as JSON, change it with `jq`, and apply the result. Turn the `inventory` datasource into the non-default one this way:

```sh
percli describe datasource prometheus -ojson | jq '.spec.default = false' | percli apply -f -
percli describe datasource prometheus -ojson | jq '{default: .spec.default, updated: .metadata.updatedAt}'
```

`default` is now `false`, and `updatedAt` has a new time while `createdAt` is unchanged: `percli apply` updated the resource in place. Set it back the same way with `.spec.default = true`.

`percli delete` removes a resource by kind and name, for example `percli delete dashboard scratch`. There is no undo, so check the selected project with `percli project` first.

## Checking a file before you apply it

`percli lint` checks resource files without changing anything. By default it runs offline, on your machine. With `--online`, it also asks the server to validate dashboards and datasources against the plugins the server actually has, through the endpoint `/api/validate/dashboards`.

Save this as `dashboard-broken.yaml`. Its panel plugin kind has a typo:

```yaml
kind: Dashboard
metadata:
  name: broken
  project: inventory
spec:
  duration: 1h
  panels:
    upTargets:
      kind: Panel
      spec:
        display:
          name: Scrape targets up
        plugin:
          kind: TimeSeriesChrat
          spec: {}
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 12
            height: 6
            content:
              $ref: "#/spec/panels/upTargets"
```

Lint it against the server:

```sh
percli lint -f dashboard-broken.yaml --online
```

The check fails and names the unknown panel plugin. Fix the kind to `TimeSeriesChart`, run the same command again, and the file passes. Linting before applying is the habit that keeps a broken file out of the server and out of Git.

You now have the everyday `percli` commands and know where its settings live. So far every command worked without a user, because authentication is off. The next step is to change that.

## Common pitfalls

> [!WARNING]
> - **Deleting in the wrong project.** `percli delete` uses the selected project. Run `percli project` before you delete anything.
> - **Committing `~/.perses/config.json`.** Once authentication is on, it holds an access token. Keep it out of Git and out of shared folders.
> - **Trusting an offline lint for plugin details.** The offline check runs on your machine; `--online` checks against the plugins the server really has.
> - **Re-creating a resource to change one field.** `describe -ojson | jq ... | apply -f -` changes the field and keeps the resource's history.
