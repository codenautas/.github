# .github

Workflows compartidos (`workflow_call`) que usan las librerías de codenautas desde sus propios
`.github/workflows/*.yml`.

## Estructura

- `.github/workflows/` — los workflows compartidos. Son los que se llaman con `uses:`.
- `.in-each-repo/` — las plantillas que hay que copiar en cada repo que consume estos workflows.
  No se ejecutan acá: están fuera de `.github/workflows/` justamente para que GitHub no las tome.

## Versionado

Los repos apuntan a un tag móvil (`@v2`). `advance-tag.bat` mueve ese tag al commit actual.

- `v1` está **congelado**. No moverlo: los repos que todavía no migraron llaman a
  `npm-publish-from-tag.yaml@v1`, que en `v2` ya no existe con ese nombre.
- `v2` es el vigente. El `.bat` lo tiene fijo.
- Un cambio que rompa compatibilidad implica congelar `v2` y pasar a `v3`.

## TODO

- **qa-control como fuente única de las plantillas.** Hoy `qa-control` verifica los workflows de
  cada repo contra su propia copia. La idea es que use como fuente los archivos de `.in-each-repo/`
  de este repo, de modo que un cambio en las plantillas se propague al control de calidad sin
  duplicar el contenido. Falta definir cómo accede `qa-control` a estos archivos (dependencia npm,
  fetch del raw, o submódulo).
