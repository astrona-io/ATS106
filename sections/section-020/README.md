# Section 020: Running And Configuring Perses

A Perses server is one program with one configuration file. That file decides whether the server accepts changes, where it keeps its resources, which resources it loads at start, and whether users must log in. On Kubernetes you rarely edit it by hand: the Helm chart writes it from your values. This section connects the three layers: the program, its configuration file, and the chart values that produce it.

**Topic covered:** installing and configuring Perses

## What you will learn

- The ways to run Perses: the binary, the container image and the Helm chart, and why the chart uses a StatefulSet for the file database.
- The sections of the configuration file, and how environment variables override it.
- Read-only mode, and what it does to the API and the user interface.
- The file database against an SQL database, and what a pod restart does to each.
- Provisioning: loading resources from folders at start and at a fixed interval.
- Mounting a ConfigMap of resources through the chart's `volumes` and `volumeMounts`, and the chart's ConfigMap sidecar.

## The learning path

Work through the module in order. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster with Perses and Prometheus where you can explore freely.

### 1. Configure Perses With Its Helm Chart

The playground holds a fresh Perses v0.54.0 installed by Helm, with no projects.

1. Ways To Run Perses
2. The Configuration File
3. Provisioning Resources At Start, followed by the lab **Provision A Project And A Global Datasource**
4. Summary

## Section capstone: Make A Perses Install Writable And Restart-Safe

The capstone combines the whole module. A Perses server refuses every change, the resources it should provision never appear, and the one provisioned datasource points at the wrong port. Fix the installation and the provisioned files, not the database. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS106.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-106-capstone-020
```
