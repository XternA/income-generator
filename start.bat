@echo off
setlocal

winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo No winget found on the system. Please install winget before proceeding.
    exit /b 1
)

wsl --version >nul 2>&1
if %errorlevel% equ 0 (
    wsl ! [ -d $HOME/.income-generator ] && call :GetTool
    call :CheckAndRegisterAlias
    wsl ${SHELL##*/} -ilc "igm"
) else (
    echo No Windows Subsystem for Linux found on the system. Ensure WSL is enabled before proceeding.
)
exit /b 0


REM -- Sub-calls -------------
:CheckAndRegisterAlias
wsl -e sh -c "if [ -f $HOME/.aliases ]; then exit 0; else exit 1; fi"
if %errorlevel% equ 0 (
    wsl grep -q "igm='(cd $HOME/.income-generator; sh start.sh)'" "$HOME/.aliases" || call :RegisterToAliases
) else (
    wsl grep -q "igm='(cd $HOME/.income-generator; sh start.sh)'" "$HOME/.${SHELL##*/}rc" || call :RegisterToRC
)
exit /b 0

:RegisterToAliases
wsl -e sh -c "echo \"alias igm='(cd $HOME/.income-generator; sh start.sh)'\" >> $HOME/.aliases"
exit /b 0

:RegisterToRC
wsl -e sh -c "echo \"alias igm='(cd $HOME/.income-generator; sh start.sh)'\" >> $HOME/.${SHELL##*/}rc"
exit /b 0

:GetTool
echo:
echo No Income Generator found. Fetching...
echo:

wsl git clone --depth=1 https://github.com/XternA/income-generator.git $HOME/.income-generator

echo:
echo Launching...
timeout /t 2 /nobreak >nul 2>&1
exit /b 0
