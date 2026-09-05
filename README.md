# .github

shared GitHub Actions workflows for codenautas libraries



language: ![English](https://raw.githubusercontent.com/codenautas/multilang/master/img/lang-en.png)
also available in:
[![Spanish](https://raw.githubusercontent.com/codenautas/multilang/master/img/lang-es.png)](LEEME.md)


## What is this

This repository holds the GitHub Actions workflows shared by almost every codenautas
library. Instead of repeating the same steps in each repository, each one has a
minimal file that delegates to the shared workflow.

This way a change of criteria (a new Node version, an added control step) is made
once here and every repository picks it up.


## Layout

- `.github/workflows/` — the shared workflows, the ones called with `uses:`.
- `.in-each-repo/` — the templates to copy into each consuming repository. They do
  not run here: they live outside `.github/workflows/` precisely so GitHub does not
  pick them up as its own.


## Versioning

Repositories point at a moving tag. The current one is `@v2`.

- `v1` is **frozen**. Repositories not yet migrated still call
  `npm-publish-from-tag.yaml@v1`, which was renamed in `v2`.
- `v2` is the current one. `advance-tag.bat` moves it to the current commit.
- A breaking change means freezing `v2` and moving on to `v3`.


```sh
$ advance-tag.bat
```


## The workflows

### `node-build-and-test.yaml`

Builds and runs the tests on a matrix of Node versions (22, 24 and 26). On the version
marked as `coverage_version` (24) it runs `npm run test-ci` instead of `npm test` and
sends the result to Coveralls.

It needs the repository to have working `npm ci` and `npm test`. The build step uses
`--if-present`, so it is optional.


### `qa-control.yaml`

Runs `qa-control` over the project and then `npm audit --omit=dev`. If the repository
has `bin/qa-control-run.js` it uses that local copy; otherwise it goes through `npx`.
That branch exists so the `qa-control` repository itself can check itself with its
working version.


### `create-new-version.yaml`

Bumps the `package.json` version, commits it on a new branch (`version/vX.Y.Z`) and
opens the pull request against the branch it was triggered from.

**It does not create the tag.** The tag is created by the publishing workflow, once
the version change is already merged. That way the tag always points at the commit
that actually gets published, and not at one left behind on a branch.

Before committing it checks that the tag for that version does not exist yet: if it
already exists it fails, because that means the version was already published.

Inputs:

- `bump` (required) — `major`, `minor`, `patch`, `premajor`, `preminor`, `prepatch`,
  `prerelease`, or a specific version like `1.2.3`.
- `preid` — the identifier for the `pre*` ones. Defaults to `beta`.
- `node_version` — defaults to `24`.


### `npm-publish-new-version.yaml`

Publishes to npm. It has two modes, depending on how the repository calls it.

**By tag** (`create-tag: false`, the default). This is the usual behavior: it is
triggered by pushing a tag, and before publishing it checks that the tag matches the
`package.json` version. If they do not match, it fails.

**Manual** (`create-tag: true`). There is no previous tag: it takes the version from
`package.json`, checks that such tag does not exist yet and creates it. If the tag
already exists it fails — that version was already published.

In both cases the publishing step is the same: `npm ci`, build, tests and
`npm publish --provenance`. The npm dist-tag comes from the version suffix: those
containing `beta`, `alpha` or `rc` are published under that tag instead of `latest`.

Inputs:

- `create-tag` — defaults to `false`.
- `node_version` — defaults to `24`.
- `skip-tests-until-date` — skips the tests until a given date (`YYYY-MM-DD`). It is
  an escape hatch for when something has to be published with broken tests for a known
  reason and with an expiration date.


## Deprecated workflows

They are still here because some repositories have not migrated yet. Both emit a
deprecation warning when they run.

- `node-test-coverage.yaml` — used to run the tests with coverage on a single Node
  version. Replaced by `node-build-and-test.yaml`, which does the same inside the
  matrix.
- `npm-publish.yaml` — the old publish. Replaced by `npm-publish-new-version.yaml`,
  which also adds `--provenance`, the automatic dist-tag and the manual mode.


## How to publish

There are two paths. Both end up in the same place.

### From the web, without a local machine

1. **Run `Create new version`** from the Actions tab, choosing the version type. It
   leaves a pull request open with the updated `package.json`.
2. **Merge that pull request** with the GitHub button.
3. **Run `Publish (manual)`** from Actions. It creates the tag from the `package.json`
   version and publishes.

### From the local machine


```sh
$ npm version patch
$ git push
$ git push --tags
```


Pushing the tag triggers `publish.yml`, which checks that the tag matches
`package.json` and publishes. This is the usual path and keeps working the same.


## What goes in each repository

These files go in each library's `.github/workflows/`, and they are ready to copy from
`.in-each-repo/`. The idea is to keep them as small as possible: everything that may
change over time lives here, not there.

### `build-and-test.yml`


```yaml
name: Build and test

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  ci:
    uses: codenautas/.github/.github/workflows/node-build-and-test.yaml@v2
```


### `qa-control.yml`


```yaml
name: QA control

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  qa:
    uses: codenautas/.github/.github/workflows/qa-control.yaml@v2
```


### `publish.yml`

The usual one: triggered by pushing a tag.


```yaml
name: Publish from tag

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]*'

permissions:
  id-token: write
  contents: read

jobs:
  publish:
    uses: codenautas/.github/.github/workflows/npm-publish-new-version.yaml@v2
    with:
      node_version: '24'
```


### `publish-manual.yml`

The same shared workflow, but triggered by hand and creating the tag. It needs
`contents: write` precisely to be able to create it.


```yaml
name: Publish (manual)

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: write

jobs:
  publish:
    uses: codenautas/.github/.github/workflows/npm-publish-new-version.yaml@v2
    with:
      node_version: '24'
      create-tag: true
```


### `create-new-version.yml`

The `choice` on `bump` is what makes GitHub show a dropdown instead of a free text
field when running it from the web.


```yaml
name: Create new version

on:
  workflow_dispatch:
    inputs:
      bump:
        description: 'Tipo de versión'
        type: choice
        required: true
        default: patch
        options: [patch, minor, major, prerelease, premajor, preminor, prepatch]
      preid:
        description: 'Identificador para los pre* (beta, alpha, rc)'
        type: string
        required: false
        default: beta

permissions:
  contents: write
  pull-requests: write

jobs:
  create-new-version:
    uses: codenautas/.github/.github/workflows/create-new-version.yaml@v2
    with:
      bump: ${{ inputs.bump }}
      preid: ${{ inputs.preid }}
      node_version: '24'
```


## Implementation details

### Why the bump does not create the tag

`npm version` normally creates the commit **and** the tag. Here `--no-git-tag-version`
is used so that it only makes the commit.

The reason: the tag created by `npm version` would point at the commit on the version
branch, which is not merged yet. After the merge that commit may not be the tip of the
main branch, and the tag would end up pointing at code different from what is
published. By creating the tag only at publishing time, it always points at what
actually gets published.

### Why manual publishing is a separate step

A push made from Actions with the `GITHUB_TOKEN` does not trigger other workflows. It
is a GitHub protection against infinite loops. That is why the tag created by the
publishing workflow could not, in turn, trigger the publication: it has to be run by
hand.

This could be avoided with a personal token, but that would mean keeping one more
secret in every repository.

### Commit identity

The commits and tags created by these workflows are attributed to whoever triggered
them, using `github.actor` and the GitHub `noreply` address. The real email is not used
because GitHub does not expose it in the Actions context.
