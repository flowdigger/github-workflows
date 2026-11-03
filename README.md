# flowdigger/github-workflows

Shared GitHub reusable workflows for flowdigger repositories.

## Reusable OWASP Dependency-Check workflow

Workflow path:

`flowdigger/github-workflows/.github/workflows/dependency-check.yml`

### Usage from plugin repository

```yaml
name: Dependency Check

on:
  push:
    branches: ["main", "release/**"]
  pull_request:
    branches: ["main"]
  workflow_dispatch:
  schedule:
    - cron: "17 2 * * *"

jobs:
  dependency-check:
    uses: flowdigger/github-workflows/.github/workflows/dependency-check.yml@v1
    secrets: inherit
    with:
      trigger-event: ${{ github.event_name }}
      upload-reports: false
```

### Inputs

- `trigger-event` (string, default: `workflow_dispatch`)  
  Pass caller event name (`${{ github.event_name }}`) to drive event-specific behavior.
- `java-version` (string, default: `21`)
- `gradle-task` (string, default: `auto`)  
  Auto resolves `dependencyCheckAnalyze` then `dependencyCheck`.
- `upload-reports` (boolean, default: `false`)
- `fail-on-missing-task` (boolean, default: `false`)

### Secrets

- `NVD_API_KEY` via `secrets: inherit` (recommended).

### Behavior

- `pull_request`: forces plugin config `autoUpdate = false` via init script for speed.
- `schedule`: performs `dependencyCheckUpdate` before scan.
- Uses cached NVD data at `~/.gradle/dependency-check-data`.
