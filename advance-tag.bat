@echo off
setlocal
if "%~1"=="" (
  echo Usage: %~nx0 ^<tag^>
  echo Example: %~nx0 v1
  exit /b 1
)
set "TAG=%~1"

git tag -f "%TAG%"
if errorlevel 1 exit /b 1

git push --force origin "%TAG%"
if errorlevel 1 exit /b 1

echo Tag %TAG% moved to the current commit and pushed.
