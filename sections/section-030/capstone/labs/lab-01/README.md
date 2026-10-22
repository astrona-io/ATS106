---
estimated_duration: 40m
---

# Lock Down An Open Perses Server

- **ID:** CAPSTONE
- **Slug:** ats-106-capstone-030
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Graded capstone for Perses in the namespace `perses`. Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the Perses v0.54.0 documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-106-capstone-030
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-106-capstone-030`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/01-install-perses.sh` | Helm, percli, the CoreDNS rewrite, Prometheus, tester and Perses |
| `bootstrap/02-seed-state.sh` | The starting state of the task |
| `manifests/` | Helm values, Prometheus and tester, the provisioned users and the open values |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/wait-for-perses.sh` | Waits until Perses answers |
| `validation/` | Grading scripts, one per check |
