# ATS106 — Fundamentals, Architecture & percli Setup (Perses)

Course material for the **Fundamentals, Architecture & percli Setup** domain
of the Astrona Perses training path ([ATP021](https://github.com/astrona-io/ATP021)),
which is **10% of the path**. Written for **Perses v0.54.0**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Perses v0.54.0 documentation, its source code and the `perses`
> Helm chart 0.23.3. None has been started on a cluster, and no lab has
> passed `astrona test` yet. See `CLAUDE.md`.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's module into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | What Perses Is And Its Resource Model | 1 | 1 + capstone | Architecture |
| [020](sections/section-020) | Running And Configuring Perses | 1 | 1 + capstone | Installation |
| [030](sections/section-030) | percli, Authentication And Authorization | 1 | 1 + capstone | percli and RBAC |

The order goes from what Perses stores, to how the server runs, to who may do
what. Section 010 builds projects, datasources and dashboards and follows a
query through the datasource proxy. Section 020 opens up the configuration
file, the Helm chart and provisioning. Section 030 turns on authentication and
gives users exactly the access they need.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Find Your Way Around Perses](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Configure Perses With Its Helm Chart](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Secure Perses And Work With percli](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Untangle Datasources Across Three Scopes | a global datasource on the wrong port, a project datasource in the wrong namespace, a dashboard-scoped datasource that bypasses the proxy |
| [020](sections/section-020/capstone/labs/lab-01) | Make A Perses Install Writable And Restart-Safe | read-only mode left on, a misspelled mount path, a provisioned file with the wrong port |
| [030](sections/section-030/capstone/labs/lab-01) | Lock Down An Open Perses Server | authentication off, sign-up on, a user bound to the global administrator role |

---

## The lab environment

Every playground and lab is a **kind** cluster with **Perses v0.54.0**
(Helm chart `perses` 0.23.3, file database on an `emptyDir`, StatefulSet
`perses`, pod `perses-0`), **Prometheus v3.15.1** in the namespace
`observability`, and a `tester` pod with `curl` and `jq`. The environment puts
**Helm 3.22.1** and **`percli` v0.54.0** on the reader's machine.

Perses answers at `http://perses.localtest.me:8080` everywhere: on the
reader's machine through `kubectl -n perses port-forward svc/perses 8080:8080`,
and inside the cluster through a CoreDNS rewrite added by the bootstrap.
Lab-only users, when authentication is on: `admin` / `perses-admin` and
`dana` / `dana-password`.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS106.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS106.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** with independent checks, and several of
them deliberately reject the plausible-but-wrong fix (re-creating a resource
instead of updating it, fixing a provisioned resource through the API,
turning authentication off, giving a user a global administrator binding).

## For authors

The shared plumbing of the nine environments (config files, author READMEs,
prerequisites, bootstrap, seed, solution, testing and validation scripts, and
the copied manifests) was generated from one Python script that is not kept in
this repository. Shared helpers such as `perses_api`, `proxy_query` and
`restart_perses` are repeated in every script: when you change one, change it
everywhere.
