# Section 010: What Perses Is And Its Resource Model

Perses is an open-source dashboard server for observability data: metrics, traces, logs and profiles. It stores every dashboard as a plain JSON or YAML document with a published specification, so you can keep dashboards in Git, check them in a build pipeline and move them between tools. Before you can do any of that, you need to know what Perses stores and how the pieces refer to each other.

This section takes a running Perses apart. You will log in with `percli`, the Perses command-line tool, create a project with a datasource and a dashboard, and follow one query from a panel through the Perses datasource proxy to Prometheus.

**Topic covered:** Perses architecture and its resource model

## What you will learn

- What Perses is, where it sits among Cloud Native Computing Foundation (CNCF) projects, and what its open specification is for.
- The difference between running the Perses server and embedding Perses panels in another application.
- The resources Perses stores: projects, dashboards, datasources, variables, secrets, folders, roles and role bindings, and their global forms.
- The three scopes of a datasource (global, project, dashboard) and which one wins when names repeat.
- The parts of a dashboard: panels, queries, layouts and the datasource reference.
- How the datasource proxy forwards a query from Perses to Prometheus.

## The learning path

Work through the module in order. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster with Perses and Prometheus where you can explore freely.

### 1. Find Your Way Around Perses

The playground holds a fresh Perses v0.54.0 with no projects, and a Prometheus server that scrapes itself.

1. What Perses Is And Where It Fits
2. Projects, Resources And Scopes
3. A First Dashboard And The Datasource Proxy, followed by the lab **Repair A Datasource And The Dashboard That Uses It**
4. Summary

## Section capstone: Untangle Datasources Across Three Scopes

The capstone combines the whole module. A datasource named `prometheus` exists at the global scope, in the project `inventory`, and inside one dashboard, and none of the three reaches Prometheus. Two dashboards in two projects show no data. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS106.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-106-capstone-010
```
