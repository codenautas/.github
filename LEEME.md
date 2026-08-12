<!--multilang v0 es:LEEME.md en:README.md -->
# .github
<!--lang:es-->

workflows compartidos de GitHub Actions para las librerías de codenautas

<!--lang:en--]

shared GitHub Actions workflows for codenautas libraries

[!--lang:*-->

<!--multilang buttons-->

idioma: ![castellano](https://raw.githubusercontent.com/codenautas/multilang/master/img/lang-es.png)
también disponible en:
[![inglés](https://raw.githubusercontent.com/codenautas/multilang/master/img/lang-en.png)](README.md)

<!--lang:es-->

## Qué es esto

Este repositorio contiene los *workflows* de GitHub Actions que comparten casi todas
las librerías de codenautas. En vez de repetir los mismos pasos en cada repositorio,
cada uno tiene un archivo mínimo que delega en el workflow compartido.

Así, un cambio de criterio (una versión nueva de Node, un paso de control agregado)
se hace una sola vez acá y lo toman todos los repositorios.

<!--lang:en--]

## What is this

This repository holds the GitHub Actions workflows shared by almost every codenautas
library. Instead of repeating the same steps in each repository, each one has a
minimal file that delegates to the shared workflow.

This way a change of criteria (a new Node version, an added control step) is made
once here and every repository picks it up.

[!--lang:es-->

## Estructura

- `.github/workflows/` — los workflows compartidos, los que se llaman con `uses:`.
- `.in-each-repo/` — las plantillas para copiar en cada repositorio que los consume.
  No se ejecutan acá: están fuera de `.github/workflows/` justamente para que GitHub
  no las tome como propias.

<!--lang:en--]

## Layout

- `.github/workflows/` — the shared workflows, the ones called with `uses:`.
- `.in-each-repo/` — the templates to copy into each consuming repository. They do
  not run here: they live outside `.github/workflows/` precisely so GitHub does not
  pick them up as its own.

[!--lang:es-->

## Versionado

Los repositorios apuntan a un tag móvil. Hoy el vigente es `@v2`.

- `v1` está **congelado**. Los repositorios que todavía no migraron siguen llamando a
  `npm-publish-from-tag.yaml@v1`, que en `v2` cambió de nombre.
- `v2` es el vigente. `advance-tag.bat` lo mueve al commit actual.
- Un cambio que rompa compatibilidad implica congelar `v2` y pasar a `v3`.

<!--lang:en--]

## Versioning

Repositories point at a moving tag. The current one is `@v2`.

- `v1` is **frozen**. Repositories not yet migrated still call
  `npm-publish-from-tag.yaml@v1`, which was renamed in `v2`.
- `v2` is the current one. `advance-tag.bat` moves it to the current commit.
- A breaking change means freezing `v2` and moving on to `v3`.

[!--lang:*-->

```sh
$ advance-tag.bat
```

<!--lang:es-->

## Los workflows

### `node-build-and-test.yaml`

Compila y corre los tests en una matriz de versiones de Node (22, 24 y 26). En la
versión marcada como `coverage_version` (24) corre `npm run test-ci` en vez de
`npm test` y manda el resultado a Coveralls.

Necesita que el repositorio tenga `npm ci` y `npm test` funcionando. El paso de build
usa `--if-present`, así que es opcional.

<!--lang:en--]

## The workflows

### `node-build-and-test.yaml`

Builds and runs the tests on a matrix of Node versions (22, 24 and 26). On the version
marked as `coverage_version` (24) it runs `npm run test-ci` instead of `npm test` and
sends the result to Coveralls.

It needs the repository to have working `npm ci` and `npm test`. The build step uses
`--if-present`, so it is optional.

[!--lang:es-->

### `qa-control.yaml`

Corre `qa-control` sobre el proyecto y después `npm audit --omit=dev`. Si el
repositorio tiene `bin/qa-control-run.js` usa esa copia local; si no, va por `npx`.
Esa bifurcación existe para que el propio repositorio `qa-control` pueda controlarse
a sí mismo con su versión de trabajo.

<!--lang:en--]

### `qa-control.yaml`

Runs `qa-control` over the project and then `npm audit --omit=dev`. If the repository
has `bin/qa-control-run.js` it uses that local copy; otherwise it goes through `npx`.
That branch exists so the `qa-control` repository itself can check itself with its
working version.

[!--lang:es-->

### `create-new-version.yaml`

Sube la versión del `package.json`, la commitea en una rama nueva (`version/vX.Y.Z`)
y abre el *pull request* contra la rama desde la que se disparó.

**No crea el tag.** El tag lo crea el workflow de publicación, una vez que el cambio
de versión ya está mergeado. De esa forma el tag siempre apunta al commit que
efectivamente se publica, y no a uno que quedó en una rama.

Antes de commitear verifica que el tag de esa versión no exista todavía: si ya existe,
falla, porque significa que esa versión ya fue publicada.

Parámetros:

- `bump` (requerido) — `major`, `minor`, `patch`, `premajor`, `preminor`, `prepatch`,
  `prerelease`, o una versión específica como `1.2.3`.
- `preid` — el identificador para los `pre*`. Por omisión `beta`.
- `node_version` — por omisión `24`.

<!--lang:en--]

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

[!--lang:es-->

### `npm-publish-new-version.yaml`

Publica en npm. Tiene dos modos, según cómo lo llame el repositorio.

**Por tag** (`create-tag: false`, que es el valor por omisión). Es el comportamiento
de siempre: lo dispara el *push* de un tag, y antes de publicar verifica que el tag
coincida con la versión del `package.json`. Si no coinciden, falla.

**Manual** (`create-tag: true`). No hay tag previo: toma la versión del `package.json`,
verifica que ese tag no exista todavía y lo crea. Si el tag ya existe, falla — esa
versión ya se publicó.

En los dos casos el paso de publicación es el mismo: `npm ci`, build, tests y
`npm publish --provenance`. El *dist-tag* de npm sale del sufijo de la versión: las
que contienen `beta`, `alpha` o `rc` se publican bajo ese tag en vez de `latest`.

Parámetros:

- `create-tag` — por omisión `false`.
- `node_version` — por omisión `24`.
- `skip-tests-until-date` — saltea los tests hasta una fecha dada (`YYYY-MM-DD`).
  Es una válvula de escape para cuando hay que publicar con tests rotos por una causa
  conocida y con fecha de vencimiento.

<!--lang:en--]

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

[!--lang:es-->

## Workflows deprecados

Siguen acá porque hay repositorios que todavía no migraron. Los dos emiten un
*warning* de deprecación al correr.

- `node-test-coverage.yaml` — corría los tests con coverage en una sola versión de
  Node. Reemplazado por `node-build-and-test.yaml`, que hace lo mismo dentro de la
  matriz.
- `npm-publish.yaml` — la versión vieja del publish. Reemplazado por
  `npm-publish-new-version.yaml`, que además agrega `--provenance`, el *dist-tag*
  automático y el modo manual.

<!--lang:en--]

## Deprecated workflows

They are still here because some repositories have not migrated yet. Both emit a
deprecation warning when they run.

- `node-test-coverage.yaml` — used to run the tests with coverage on a single Node
  version. Replaced by `node-build-and-test.yaml`, which does the same inside the
  matrix.
- `npm-publish.yaml` — the old publish. Replaced by `npm-publish-new-version.yaml`,
  which also adds `--provenance`, the automatic dist-tag and the manual mode.

[!--lang:es-->

## Cómo publicar

Hay dos caminos. Los dos terminan en el mismo lugar.

### Desde la web, sin máquina local

1. **Correr `Create new version`** desde la solapa Actions, eligiendo el tipo de
   versión. Deja abierto un *pull request* con el `package.json` actualizado.
2. **Mergear ese pull request** con el botón de GitHub.
3. **Correr `Publish (manual)`** desde Actions. Crea el tag a partir de la versión del
   `package.json` y publica.

### Desde la máquina local

<!--lang:en--]

## How to publish

There are two paths. Both end up in the same place.

### From the web, without a local machine

1. **Run `Create new version`** from the Actions tab, choosing the version type. It
   leaves a pull request open with the updated `package.json`.
2. **Merge that pull request** with the GitHub button.
3. **Run `Publish (manual)`** from Actions. It creates the tag from the `package.json`
   version and publishes.

### From the local machine

[!--lang:*-->

```sh
$ npm version patch
$ git push
$ git push --tags
```

<!--lang:es-->

El *push* del tag dispara `publish.yml`, que valida que el tag coincida con el
`package.json` y publica. Es el camino de siempre y sigue funcionando igual.

<!--lang:en--]

Pushing the tag triggers `publish.yml`, which checks that the tag matches
`package.json` and publishes. This is the usual path and keeps working the same.

[!--lang:es-->

## Qué poner en cada repositorio

En `.github/workflows/` de cada librería van estos archivos, que están en
`.in-each-repo/` listos para copiar. La idea es que sean lo más chicos posible: todo
lo que pueda cambiar con el tiempo vive acá, no allá.

### `build-and-test.yml`

<!--lang:en--]

## What goes in each repository

These files go in each library's `.github/workflows/`, and they are ready to copy from
`.in-each-repo/`. The idea is to keep them as small as possible: everything that may
change over time lives here, not there.

### `build-and-test.yml`

[!--lang:*-->

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

<!--lang:es-->

### `qa-control.yml`

<!--lang:en--]

### `qa-control.yml`

[!--lang:*-->

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

<!--lang:es-->

### `publish.yml`

El de siempre: lo dispara el *push* de un tag.

<!--lang:en--]

### `publish.yml`

The usual one: triggered by pushing a tag.

[!--lang:*-->

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

<!--lang:es-->

### `publish-manual.yml`

El mismo workflow compartido, pero disparado a mano y creando el tag. Necesita
`contents: write` justamente para poder crearlo.

<!--lang:en--]

### `publish-manual.yml`

The same shared workflow, but triggered by hand and creating the tag. It needs
`contents: write` precisely to be able to create it.

[!--lang:*-->

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

<!--lang:es-->

### `create-new-version.yml`

El `choice` de `bump` es lo que hace que GitHub muestre un desplegable en vez de un
campo de texto libre al correrlo desde la web.

<!--lang:en--]

### `create-new-version.yml`

The `choice` on `bump` is what makes GitHub show a dropdown instead of a free text
field when running it from the web.

[!--lang:*-->

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

<!--lang:es-->

## Detalles de implementación

### Por qué el bump no crea el tag

`npm version` normalmente crea el commit **y** el tag. Acá se usa
`--no-git-tag-version` para que solo haga el commit.

La razón: el tag creado por `npm version` apuntaría al commit de la rama de versión,
que todavía no está mergeado. Después del merge ese commit puede no ser la punta de la
rama principal, y el tag quedaría apuntando a un código distinto del que está
publicado. Creando el tag recién en el momento de publicar, siempre apunta a lo que
efectivamente se publica.

### Por qué la publicación manual es un paso aparte

Un *push* hecho desde Actions con el `GITHUB_TOKEN` no dispara otros workflows. Es una
protección de GitHub contra los bucles infinitos. Por eso el tag que crea el workflow
de publicación no podría, a su vez, disparar la publicación: hay que correrla a mano.

Se podría evitar usando un token personal, pero eso obligaría a mantener un secret más
en cada repositorio.

### Identidad de los commits

Los commits y tags que crean estos workflows quedan atribuidos a quien los disparó,
usando `github.actor` y la dirección `noreply` de GitHub. El mail real no se usa porque
GitHub no lo expone en el contexto de Actions.

<!--lang:en--]

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

[!--lang:*-->
