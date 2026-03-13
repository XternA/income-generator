@echo off
setlocal

set ARGS=%*
set REPO=https://github.com/XternA/income-generator.git
set IGM_PATH=~/.igm
set INIT_MARKER=%APPDATA%\IGM\.initialised

REM 'igm init' command
if "%1"=="init" (
    call :InitialiseIGM
    exit /b 0
)

REM Check if initialised
if not exist "%INIT_MARKER%" (
    echo IGM is not initialised. Run 'igm init' first.
    exit /b 1
)

REM Direct execution
wsl sh -c "cd %IGM_PATH% 2>/dev/null || { echo 'IGM is not initialised. Run 'igm init' first.' >&2; exit 1; }; sh start.sh %ARGS%"
exit /b %ERRORLEVEL%


REM -- Setup Command -------------
:InitialiseIGM
echo Initialising IGM...
echo.

where wsl >nul 2>&1 || (
    echo No Windows Subsystem for Linux found on the system. Ensure WSL is enabled before proceeding.
    exit /b 1
)

REM Get repo if don't exist
wsl sh -c "[ -d %IGM_PATH% ] || git clone --depth=1 %REPO% %IGM_PATH% >/dev/null 2>&1"

REM Register alias inside WSL
echo Registering WSL alias...
wsl sh -c "RC=~/.aliases; [ ! -f \"\$RC\" ] && RC=~/.\${SHELL##*/}rc; grep -q 'alias igm=' \"\$RC\" 2>/dev/null || echo \"alias igm=\\\"sh -c 'cd %IGM_PATH%; sh start.sh \\\\\\\"\\\\\\\$@\\\\\\\"' --\\\"\" >> \"\$RC\""

REM Create directory if needed and mark as initialised
if not exist "%APPDATA%\IGM" mkdir "%APPDATA%\IGM"
type nul > "%INIT_MARKER%"

echo IGM initialised successfully!
echo.
echo You can now use 'igm' commands.
echo For WSL users, restart your shell to use the 'igm' command.
exit /b 0
