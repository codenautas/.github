@echo off
setlocal
rem El tag vigente de los shared workflows. Cambiarlo solo en el proximo breaking change.
rem v1 quedo congelado para los repos que todavia no migraron.
set "TAG=v2"

git tag -f "%TAG%"
if errorlevel 1 exit /b 1

git push --force origin "%TAG%"
if errorlevel 1 exit /b 1

echo Tag %TAG% moved to the current commit and pushed.
