@echo off
setlocal

set ARGS="%*"
set REPO="https://github.com/XternA/income-generator.git"
set TOOL_DIR="~/.income-generator"

winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo No winget found on the system. Please install winget before proceeding.
    exit /b 1
)

wsl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo No Windows Subsystem for Linux found on the system. Ensure WSL is enabled before proceeding.
    exit /b 1
)

call :CheckAndRegisterAlias
wsl ${SHELL##*/} -ilc "echo; [ ! -d %TOOL_DIR% ] && git clone --depth=1 %REPO% %TOOL_DIR%; sleep 3; igm %ARGS%"
exit /b 0


REM -- Sub-calls -------------
:CheckAndRegisterAlias
wsl -e sh -c "[ -f $HOME/.aliases ]"
if %errorlevel% equ 0 (
    wsl grep -q "alias igm=" "$HOME/.aliases" || call :RegisterToAliases
) else (
    wsl grep -q "alias igm=" "$HOME/.${SHELL##*/}rc" || call :RegisterToRC
)
exit /b 0

:RegisterToAliases
wsl -e sh -c "echo 'alias igm=\"sh -c '\''cd %TOOL_DIR%; sh start.sh \\\"\\$@\\\"'\'' --\"' >> $HOME/.aliases"
exit /b 0

:RegisterToRC
wsl -e sh -c "echo 'alias igm=\"sh -c '\''cd %TOOL_DIR%; sh start.sh \\\"\\$@\\\"'\'' --\"' >> $HOME/.${SHELL##*/}rc"
exit /b 0
