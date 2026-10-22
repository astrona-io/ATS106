# Section 030: percli, Authentication And Authorization

A Perses server with authentication off lets anybody who reaches it change anything. That is fine on your laptop and wrong everywhere else. This section first makes you fluent with `percli`, the Perses command-line tool, then turns on authentication with native users, and finally gives each user exactly the access they need with roles and role bindings.

**Topic covered:** percli, authentication and authorization

## What you will learn

- Logging `percli` in, its configuration file, and selecting a project.
- Getting, describing, applying, deleting and linting resources with `percli`, and using JSON output with `jq`.
- Turning on authentication with the native provider, and what changes for the API and for `percli`.
- Provisioning users and a global administrator, and turning off sign-up.
- `Role`, `RoleBinding`, `GlobalRole` and `GlobalRoleBinding`: actions, scopes and subjects.
- Checking what a user can and cannot do by logging in as that user.

## The learning path

Work through the module in order. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster with Perses and Prometheus where you can explore freely.

### 1. Secure Perses And Work With percli

The playground holds Perses v0.54.0 with authentication off and two projects, `inventory` and `billing`, each with a Prometheus datasource.

1. Working With percli
2. Turning On Authentication
3. Roles And Role Bindings, followed by the lab **Give A User Edit Rights On One Project**
4. Summary

## Section capstone: Lock Down An Open Perses Server

The capstone combines the whole module. A Perses server runs with authentication off and sign-up allowed, and the user `dana` was made a global administrator "to get her started". Lock the server down so anonymous requests are refused, nobody can sign up, and `dana` can change dashboards in `inventory` and nowhere else. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS106.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-106-capstone-030
```
