@echo off
setlocal

winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo No winget found on the system. Please install winget before proceeding.
    exit /b 1
)

wsl --version >nul 2>&1
if %errorlevel% equ 0 (
    wsl [ -d ~/.income-generator ] && wsl "${SHELL##*/}" -ilc "igm" || (
        echo No Income Generator Tool found. Fetching...
        echo:

        wsl git clone --depth=1 https://github.com/XternA/income-generator.git ~/.income-generator
        wsl grep -q "igm='(cd ~/.income-generator; sh start.sh)'" ~/."${SHELL##*/}"rc || (
            wsl echo "alias igm='(cd ~/.income-generator; sh start.sh)'" >> ~/."${SHELL##*/}"rc
            wsl source ~/."${SHELL##*/}"rc
        )

        echo:
        echo Launching...
        timeout /t 2 /nobreak >nul 2>&1
        wsl "${SHELL##*/}" -ilc "igm"
    )
) else (
    echo No Windows Subsystem for Linux found on the system. Ensure WSL is enabled before proceeding.
)
