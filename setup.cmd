@echo off
setlocal EnableDelayedExpansion

REM ==========================================================================
REM  setup.cmd - Point Claude Code at the local OpenCode proxy
REM
REM  Adds/updates these values in %USERPROFILE%\.claude\settings.json
REM    env.ANTHROPIC_BASE_URL  = http://127.0.0.1:8084
REM    env.ANTHROPIC_API_KEY   = public
REM    enableArtifact           = false
REM
REM  * Fresh install  -> creates the file if missing
REM  * Existing install -> merges (all other settings preserved)
REM  * Proxy check    -> warns if port 8084 is not listening
REM ==========================================================================

set "PROXY_URL=http://127.0.0.1:8084"
set "PROXY_KEY=public"
set "CLAUDE_DIR=%USERPROFILE%\.claude"
set "SETTINGS_FILE=%CLAUDE_DIR%\settings.json"

echo.
echo  ================================================
echo   Claude Code  ^<^>  OpenCode Proxy Setup
echo  ================================================
echo.

REM -- Step 1: is the proxy listening? ----------------------------------------
echo  [1/3] Checking proxy on %PROXY_URL% ...
netstat -ano | findstr /C:"127.0.0.1:8084" | findstr /C:"LISTENING" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo        [OK] Proxy is running
) else (
    echo        [WARN] Proxy NOT detected on port 8084
    echo        [WARN] Start it first:  cargo run --release
    echo        [WARN] ^(settings will still be saved — proxy only needs^)
    echo        [WARN] ^(to be up when Claude Code runs^)
)
echo.

REM -- Step 2: ensure .claude\ exists ------------------------------------------
echo  [2/3] Checking settings file ...
if not exist "%CLAUDE_DIR%" (
    mkdir "%CLAUDE_DIR%"
    echo        Created  %CLAUDE_DIR%
)
if not exist "%SETTINGS_FILE%" (
    echo        Fresh install - creating %SETTINGS_FILE%
    set "FRESH_INSTALL=1"
) else (
    echo        Found  %SETTINGS_FILE%
    set "FRESH_INSTALL=0"
)
echo.

REM -- Step 3: apply settings --------------------------------------------------
echo  [3/3] Applying proxy settings ...
echo.

if !FRESH_INSTALL! EQU 1 (
    REM -- Fresh install: write the whole file with echo (no PowerShell needed)
    (
        echo {
        echo   "env": {
        echo     "ANTHROPIC_BASE_URL": "%PROXY_URL%",
        echo     "ANTHROPIC_API_KEY": "%PROXY_KEY%"
        echo   },
        echo   "enableArtifact": false
        echo }
    ) > "%SETTINGS_FILE%"
    echo        Fresh file written.
) else (
    REM -- Existing install: use PowerShell so existing keys are preserved
    call :MERGE_JSON
)

echo.
echo  ================================================
echo   DONE
echo  ================================================
echo.
echo   Settings file : %SETTINGS_FILE%
echo   ANTHROPIC_BASE_URL  = %PROXY_URL%
echo   ANTHROPIC_API_KEY   = %PROXY_KEY%
echo   enableArtifact        = false
echo.
echo   Next steps:
echo     1. Start proxy  : cargo run --release
echo     2. Run Claude Code as normal
echo.
pause
exit /b 0

REM ==========================================================================
REM  Merge proxy env vars into an existing settings.json without
REM  touching any other keys.  Uses PowerShell 5.1 (always present
REM  on Windows 10/11).
REM ==========================================================================
:MERGE_JSON
set "PS_SCRIPT=%TEMP%\claude_proxy_setup.ps1"

REM  Write the PS script line by line to avoid cmd-quoting hell
>  "%PS_SCRIPT%" echo $f = '%SETTINGS_FILE%'
>> "%PS_SCRIPT%" echo $j = Get-Content -Raw $f ^| ConvertFrom-Json
>> "%PS_SCRIPT%" echo if ($null -eq $j.env) {
>> "%PS_SCRIPT%" echo     $j ^| Add-Member -NotePropertyName 'env' -NotePropertyValue (New-Object PSObject)
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo $j.env ^| Add-Member -NotePropertyName 'ANTHROPIC_BASE_URL' -NotePropertyValue '%PROXY_URL%' -Force
>> "%PS_SCRIPT%" echo $j.env ^| Add-Member -NotePropertyName 'ANTHROPIC_API_KEY'  -NotePropertyValue '%PROXY_KEY%'  -Force
>> "%PS_SCRIPT%" echo $j ^| Add-Member -NotePropertyName 'enableArtifact' -NotePropertyValue $false -Force
>> "%PS_SCRIPT%" echo Set-Content -Path $f -Value ($j ^| ConvertTo-Json -Depth 10) -Encoding UTF8

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
if !ERRORLEVEL! NEQ 0 (
    echo        [ERROR] PowerShell merge failed. Run this file as admin.
    pause
    exit /b 1
)

del "%PS_SCRIPT%" >nul 2>&1
echo        Existing settings preserved, proxy vars merged.
exit /b 0
