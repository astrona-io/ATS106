# Welcome To The Course

This course trains you for the **Fundamentals, Architecture & percli Setup** part of the Astrona **Perses** training path. That part is 10% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Services, ConfigMaps, StatefulSets, `kubectl get`, `kubectl logs` and `kubectl port-forward`. You can run `helm upgrade` with a values file. You know what a metric is and can read a short Prometheus query such as `up`. You do not need to know Perses. Each new idea is explained the first time it appears.

## What you can do at the end

Perses is a dashboard server you run and talk to, so this course does not ask you to remember words. It asks you to create and repair resources, change how the server runs, and prove that a user can do exactly what they should. The course has three topics, and each one turns into a set of skills you will practise.

The first topic is **what Perses is and its resource model**. You will learn to:

- Explain what Perses is, what its open dashboard specification is for, and how the server differs from the embedded npm packages.
- Create projects, datasources and dashboards with `percli`, the Perses command-line tool.
- Work out which datasource a dashboard uses when the same name exists at the global, project and dashboard scopes.
- Test a datasource through the Perses datasource proxy.

The second topic is **running and configuring Perses**. You will learn to:

- Run Perses as a binary, a container or with its Helm chart, and find what the chart created.
- Read and change the configuration file through the chart values, including read-only mode.
- Provision resources from a ConfigMap so they come back after every restart.

The third topic is **`percli`, authentication and authorization**. You will learn to:

- Use `percli` every day: log in, select a project, get, describe, apply, delete and lint.
- Turn on authentication with native users and turn off sign-up.
- Give a user exactly the access they need with roles and role bindings, and prove it.

Everything is written for **Perses v0.54.0**.

## The words this course uses

The pages use Perses's and Kubernetes's own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **resource** is a JSON or YAML document that Perses stores and serves through its REST API, with a `kind`, `metadata` and a `spec`. A **project** groups the resources of one team. A **dashboard** holds panels, and each panel runs queries. A **datasource** holds the settings to reach a data backend such as Prometheus. A **plugin** is the code behind one type of panel, datasource, query or variable.

Perses sends every query on behalf of the browser, through its datasource proxy:

| Piece | What it does |
| --- | --- |
| Panel | Draws the result of one or more queries, for example as a time series chart |
| Query | Holds the query text, such as the PromQL `up`, and names a datasource |
| Datasource | Holds the URL of the backend, for example `http://prometheus.observability:9090` |
| Datasource proxy | The Perses API path that forwards a query to the datasource's URL |

## The example setup in your playground

Every playground and lab runs the same small setup. Perses runs in the namespace `perses` as one pod, `perses-0`, behind the Service `perses`. Prometheus runs in the namespace `observability` and scrapes itself, so the metric `up` always has data. A `tester` pod with `curl` and `jq` sends requests from inside the cluster.

The pages use the same names everywhere: the project `inventory` for the main team and `billing` for a second team, a datasource called `prometheus`, and, once authentication is on, the users `admin` and `dana`. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections. It starts with what Perses stores, then how the server runs and is configured, and ends with who may do what.

| Section | What it covers |
| --- | --- |
| 010 | What Perses Is And Its Resource Model |
| 020 | Running And Configuring Perses |
| 030 | percli, Authentication And Authorization |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
