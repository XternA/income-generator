@echo off
setlocal

set ARGS="%*"
set REPO="https://github.com/XternA/income-generator.git"
set TOOL_DIR="~/.igm"

where winget >nul 2>&1 || (
    echo No winget found on the system. Please install winget before proceeding.
    exit /b 1
)

where wsl >nul 2>&1 || (
    echo No Windows Subsystem for Linux found on the system. Ensure WSL is enabled before proceeding.
    exit /b 1
)

call :CheckAndRegisterAlias
wsl ${SHELL##*/} -ilc "echo; [ ! -d %TOOL_DIR% ] && git clone --depth=1 %REPO% %TOOL_DIR%; sleep 3; igm %ARGS%"
exit /b 0


REM -- Sub-calls -------------
:CheckAndRegisterAlias
wsl -e sh -c "if [ -f $HOME/.aliases ]; then grep -q 'alias igm=' $HOME/.aliases || echo 'REGISTER_ALIASES'; else grep -q 'alias igm=' $HOME/.${SHELL##*/}rc || echo 'REGISTER_RC'; fi" > %TEMP%\igm_check.tmp
findstr /C:"REGISTER_ALIASES" %TEMP%\igm_check.tmp >nul 2>&1 && call :RegisterToAliases
findstr /C:"REGISTER_RC" %TEMP%\igm_check.tmp >nul 2>&1 && call :RegisterToRC
del %TEMP%\igm_check.tmp >nul 2>&1
exit /b 0

:RegisterToAliases
wsl -e sh -c "echo 'alias igm=\"sh -c '\''cd %TOOL_DIR%; sh start.sh \\\"\\$@\\\"'\'' --\"' >> $HOME/.aliases"
exit /b 0

:RegisterToRC
wsl -e sh -c "echo 'alias igm=\"sh -c '\''cd %TOOL_DIR%; sh start.sh \\\"\\$@\\\"'\'' --\"' >> $HOME/.${SHELL##*/}rc"
exit /b 0
