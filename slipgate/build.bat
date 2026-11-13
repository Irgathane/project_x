@echo off
setlocal
cd /d "%~dp0"
echo === SLIPGATE KIT BUILD ===

set "QCC=fteqcc"
where fteqcc >nul 2>nul
if errorlevel 1 (
  if exist "tools\fteqcc.exe" (set "QCC=tools\fteqcc.exe") else (
    echo [!] fteqcc not found. Put fteqcc.exe in tools\ or add it to PATH.
    echo     Download: https://www.fteqcc.org/
    goto :fail
  )
)

pushd qc
"%QCC%" progs.src
if errorlevel 1 (popd & goto :fail)
copy /y progs.dat ..\progs.dat >nul
popd
echo [ok] progs.dat built

where qbsp >nul 2>nul
if errorlevel 1 (
  echo [skip] qbsp not in PATH - map not compiled.
  echo        ericw-tools: https://github.com/ericwa/ericw-tools/releases
  goto :done
)
pushd maps
qbsp -wadpath . starter.map
if errorlevel 1 (popd & goto :fail)
vis starter.bsp
light starter.bsp
popd
echo [ok] starter.bsp built

:done
echo Done. Run launch.bat
exit /b 0
:fail
echo Build FAILED - paste the error into LLM prompt #3 (docs/PROMPTS.md)
exit /b 1
