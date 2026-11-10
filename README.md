# flowdigger/github-workflows

Shared GitHub reusable workflows for flowdigger repositories.

## Reusable Maven Central publish workflow (recommended)

Workflow path:

`flowdigger/github-workflows/.github/workflows/publish-maven-central.yml`

### Usage from consumer repository

```yaml
name: Release

on:
  push:
    tags:
      - "v*"
  workflow_dispatch:

jobs:
  publish:
    uses: flowdigger/github-workflows/.github/workflows/publish-maven-central.yml@main
    secrets: inherit
    with:
      java-version: "21"
      gradle-task: "publish"
      central-namespace: "org.flowdigger"
      clone-flowdigger-gradle: true
      flowdigger-gradle-ref: "main"
```

### Inputs

- `java-version` (string, default: `21`)
- `gradle-task` (string, default: `publish`)
- `clone-flowdigger-gradle` (boolean, default: `true`)  
  Clones `../flowdigger-gradle` in runner so consumer `includeBuild("../flowdigger-gradle")` works in CI.
- `flowdigger-gradle-ref` (string, default: `main`)  
  Git ref used for cloned `flowdigger-gradle` repository.
- `fallback-owner` (string, default: `flowdigger`)  
  Owner/org fallback if clone from caller owner fails.
- `central-namespace` (string, default: `org.flowdigger`)  
  Namespace sent to Central Publisher API upload endpoint.
- `staging-directory` (string, default: `build/test-repository`)  
  Directory containing staged Maven repository files to be bundled and uploaded.
- `upload-artifacts` (boolean, default: `true`)  
  Uploads publish log, Central API response, and generated bundle as workflow artifacts.

### Required secrets

- `MAVEN_CENTRAL_USERNAME`
- `MAVEN_CENTRAL_PASSWORD`
- `SIGNING_KEY`
- `SIGNING_PASSWORD`

### Behavior

- Builds signed artifacts with `FLOWDIGGER_PUBLISH_TARGET=local-test`.
- Creates Central bundle from staged repository, adds `.md5` and `.sha1` files, uploads bundle to Central Publisher API.
- Supports composite-build plugin resolution in CI by cloning `flowdigger-gradle` beside workspace.
- Keeps caller workflow minimal (trigger + reusable call).

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
- `clone-flowdigger-gradle` (boolean, default: `false`)  
  Clones `../flowdigger-gradle` when consumer repo uses composite plugin includeBuild.
- `flowdigger-gradle-ref` (string, default: `main`)
- `fallback-owner` (string, default: `flowdigger`)

### Secrets

- `NVD_API_KEY` via `secrets: inherit` (recommended).

### Behavior

- `pull_request`: forces plugin config `autoUpdate = false` via init script for speed.
- `schedule`: performs `dependencyCheckUpdate` before scan.
- Uses cached NVD data at `~/.gradle/dependency-check-data`.

## Reusable Maven Central release workflow

Legacy advanced workflow retained for compatibility.

Workflow path:

`flowdigger/github-workflows/.github/workflows/maven-central-release.yml`

### Usage from plugin repository

```yaml
name: Release to Maven Central

on:
  workflow_dispatch:
  push:
    branches:
      - "release/**"
      - "snapshot/**"
      - "snapshots/**"
    tags:
      - "v*"

jobs:
  release:
    permissions:
      contents: read
    uses: flowdigger/github-workflows/.github/workflows/maven-central-release.yml@main
    with:
      trigger-event: ${{ github.event_name }}
      java-version: "21"
      central-namespace: "org.flowdigger"
      clone-composite-build-deps: true
      upload-artifacts: true
      publish-snapshot-branches: true
      snapshot-branch-prefix: "refs/heads/snapshot/"
      snapshot-publish-task: "clean publish"
    secrets: inherit
```

### Inputs

- `trigger-event` (string, default: `workflow_dispatch`)
- `java-version` (string, default: `21`)
- `verify-task` (string, default: `clean test`)
- `publish-task` (string, default: `clean packageCentralBundle`)
- `central-namespace` (string, default: `org.flowdigger`)
- `bundle-glob` (string, default: `build/central-bundle/*.zip`)
- `clone-composite-build-deps` (boolean, default: `true`)
- `fallback-owner` (string, default: `flowdigger`)
- `upload-artifacts` (boolean, default: `true`)
- `publish-snapshot-branches` (boolean, default: `false`)
- `snapshot-branch-prefix` (string, default: `refs/heads/snapshot/`)
- `snapshot-publish-task` (string, default: `clean publish`)

### Secrets

- `MAVEN_CENTRAL_USERNAME`
- `MAVEN_CENTRAL_PASSWORD`
- `SIGNING_KEY`
- `SIGNING_PASSWORD`
- `SIGNING_KEY_ID` (optional, if project build needs it; accepts `0x`-prefixed/plain key id or full fingerprint)

### Behavior

- `push` to `release/**`: runs verify task only.
- `workflow_dispatch` and `v*` tags: runs publish task and uploads bundle to Central API.
- Optional `snapshot*` branches can run snapshot publish task for publish-path testing.
- Optionally clones known `includeBuild` dependencies before Gradle execution.
- Release publish path runs Gradle dry-run preflight and fails early if publish task graph contains no `sign*Publication` tasks.
- Publish job normalizes `SIGNING_KEY_ID` (trim whitespace/newlines, remove `0x`, uppercase). If longer value is provided (for example long key id/fingerprint), workflow derives low 8 hex chars for Gradle signing compatibility; if still invalid, workflow fails fast with explicit error.
