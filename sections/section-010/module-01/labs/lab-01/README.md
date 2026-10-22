---
estimated_duration: 20m
---

# Repair A Datasource And The Dashboard That Uses It

- **ID:** LAB
- **Slug:** ats-106-lab-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for Perses in the namespace `perses`. Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the Perses v0.54.0 documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-106-lab-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-106-lab-010-01`), not
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
| `manifests/` | Helm values, Prometheus and tester |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/wait-for-perses.sh` | Waits until Perses answers |
| `validation/` | Grading scripts, one per check |
