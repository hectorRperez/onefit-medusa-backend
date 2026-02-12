## CLI Test Workflow (test-cli.yml)

### Overview

This GitHub Actions workflow aims to verify that the Medusa backend can:

- Install dependencies correctly

- Compile without errors

- Run migrations

- Run the seed

- Start the server

- Respond to a basic HTTP request

When does it run? 

```
on:
  pull_request:
    branches:
      - master
      - ci
```

What is the real purpose of this workflow?

- This file does NOT run unit tests.
- It does not validate business logic.
- It does not test custom endpoints.

It is solely a:

Smoke Test

- It verifies that the project:
- Can be installed
- Can be compiled
- Can be migrated
- Can be started
- Can be responsive
- In a completely clean environment.