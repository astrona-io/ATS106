# Secure Perses And Work With percli — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-106-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment that installs Perses v0.54.0, Prometheus and a
tester pod, then stays running so you can explore the module's topic. Nothing
to submit. Built from the Perses v0.54.0 documentation and not yet run.

## Run it

```sh
astrona run -c .
astrona destroy ats-106-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-106-playground-030-01`), not
the config path. `astrona submit` and `astrona test` do not apply.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/prepare.sh` | Helm, percli, CoreDNS rewrite, Prometheus, tester, Perses, projects `inventory` and `billing` |
| `manifests/perses-values.yaml` | Helm values for Perses |
| `manifests/lab-start.yaml` | Prometheus and the tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
