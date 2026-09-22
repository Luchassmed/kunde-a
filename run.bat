@echo off
setlocal enabledelayedexpansion

set "ENVNAME=%~1"
if "%ENVNAME%"=="" set "ENVNAME=sandbox"

set "ROOT=%~dp0"
set "COMMON_DIR=%ROOT%common"

if not exist "%COMMON_DIR%\.git" (
  echo [FEJL] common\ er ikke initialiseret. Koer: git submodule update --init --recursive
  exit /b 1
)

set "TARGET_BRANCH=main"
if "%ENVNAME%"=="sandbox" set "TARGET_BRANCH=sandbox"

set "DIRTY="
for /f "delims=" %%S in ('git -C "%COMMON_DIR%" status --porcelain --untracked-files=no') do set "DIRTY=1"
if defined DIRTY (
  echo [FEJL] common\ har lokale, ikke-committede aendringer - afbryder for ikke at miste dem.
  exit /b 1
)

echo Skifter common til branch '%TARGET_BRANCH%' ^(miljoe: %ENVNAME%^)...
call git -C "%COMMON_DIR%" fetch origin %TARGET_BRANCH%
if errorlevel 1 exit /b 1
call git -C "%COMMON_DIR%" checkout -B %TARGET_BRANCH% origin/%TARGET_BRANCH%
if errorlevel 1 exit /b 1

call "%COMMON_DIR%\run.bat" %ENVNAME%
exit /b %ERRORLEVEL%
