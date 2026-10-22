# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Every section needs the same set of tools. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster.
- **The astrona command-line tool.**
- **`jq`:** reads JSON, so you can pick out one field of a Perses resource.
- **A web browser:** to open the Perses user interface.

Two more tools come with every environment, so you do not install them yourself: **Helm 3.22.1** and **`percli` v0.54.0**, the Perses command-line tool. Each playground and lab puts the pinned versions in `/usr/local/bin` or `~/.local/bin`, so the versions always match the server.

The playgrounds and labs need **outbound internet** while they start. They download Helm, `percli` and the Perses Helm chart, and they pull the Perses, Prometheus and tester images. Without outbound internet, those starts fail with errors that have nothing to do with Perses.

## Reaching Perses

Perses runs inside the cluster, so your machine reaches it through a port-forward. Every page that uses `percli`, `curl` or the browser asks you to start it in a second terminal and leave it running:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

The address is always `http://perses.localtest.me:8080`. The name `perses.localtest.me` is a public DNS name that points at `127.0.0.1`, your own machine, so the port-forward answers it. Inside the cluster, the same name points at the Perses Service, so the pages and the graders use one address.

Some home routers block DNS answers that point at `127.0.0.1`. If a command says it cannot resolve `perses.localtest.me`, add this line to `/etc/hosts` on your machine:

```
127.0.0.1 perses.localtest.me
```

A port-forward ends when the pod it points at restarts. Several modules restart Perses on purpose, so start the port-forward again whenever a command suddenly cannot connect.

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything. On macOS it can install `kind`, `kubectl` and Podman. Install `jq` yourself.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS106.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It calls the Perses API, logs in as the lab's users and checks the Helm release, so your fix has to actually work, not only make an error message go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-106-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own Perses. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start fails while it downloads something, check your network first. If `percli` or `curl` cannot reach Perses, check that the port-forward is still running in your second terminal. Remember also that a lab that starts with an empty panel or a refused change is often broken on purpose: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
