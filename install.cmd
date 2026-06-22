@echo off
setlocal EnableDelayedExpansion

set REPO=XternA/income-generator
set INSTALLER_URL=https://raw.githubusercontent.com/%REPO%/installer
set IGM_DIR=%APPDATA%\IGM
set WSL_GUIDE=https://github.com/%REPO%/wiki/Windows-Guide

echo.

REM Check WSL is available and a distro is configured
wsl -e true >nul 2>&1
if %errorlevel% neq 0 (
    echo   x WSL2 is not available or no Linux distribution is configured.
    echo     Install guide: %WSL_GUIDE%
    echo.
    exit /b 1
)

REM Create IGM directory if it doesn't exist
mkdir "%IGM_DIR%" 2>nul

REM Clean up legacy initialisation marker from v2
del "%IGM_DIR%\.initialised" 2>nul

REM Download igm.bat
echo =^> Downloading Windows loader...
curl -fsSL "%INSTALLER_URL%/igm.bat" -o "%IGM_DIR%\igm.bat"
if %errorlevel% neq 0 (
    echo   x Failed to download igm.bat. Check your internet connection and try again.
    echo.
    exit /b 1
)
echo     Done

REM Update PATH
powershell -NoProfile -Command "& { $d = '%IGM_DIR%'; $p = [Environment]::GetEnvironmentVariable('PATH','User'); if ([string]::IsNullOrEmpty($p)) { [Environment]::SetEnvironmentVariable('PATH', $d, 'User') } elseif ($p -notlike ('*' + $d + '*')) { [Environment]::SetEnvironmentVariable('PATH', $d + ';' + $p, 'User') } }" >nul 2>&1
set "PATH=%IGM_DIR%;%PATH%"

REM Run install.sh inside WSL
echo =^> Setting up IGM...
echo.
wsl -- sh -c "curl -fsSL '%INSTALLER_URL%/install.sh' | sh"
if %errorlevel% neq 0 (
    echo.
    echo   x IGM setup failed. See output above for details.
    echo.
    exit /b 1
)

echo.
endlocal
