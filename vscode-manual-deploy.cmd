@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Defaults
rem ============================================================
set "REMOTE_USER="
set "REMOTE_HOST="
set "REMOTE_PORT=22"

rem ============================================================
rem Parse command-line arguments
rem ============================================================
:parse_args
if "%~1"=="" goto validate_args

if /I "%~1"=="-u" (
    if "%~2"=="" (
        echo ERROR: Missing value for -u.
        goto usage_error
    )
    set "REMOTE_USER=%~2"
    shift
    shift
    goto parse_args
)

if /I "%~1"=="-h" (
    if "%~2"=="" (
        echo ERROR: Missing value for -h.
        goto usage_error
    )
    set "REMOTE_HOST=%~2"
    shift
    shift
    goto parse_args
)

if /I "%~1"=="-p" (
    if "%~2"=="" (
        echo ERROR: Missing value for -p.
        goto usage_error
    )
    set "REMOTE_PORT=%~2"
    shift
    shift
    goto parse_args
)

if /I "%~1"=="/?" goto usage
if /I "%~1"=="--help" goto usage

echo ERROR: Unknown argument: %~1
goto usage_error

rem ============================================================
rem Validate arguments
rem ============================================================
:validate_args
if not defined REMOTE_USER (
    echo ERROR: Remote user is required.
    goto usage_error
)

if not defined REMOTE_HOST (
    echo ERROR: Remote host is required.
    goto usage_error
)

rem Validate that the port contains only digits
for /f "delims=0123456789" %%A in ("!REMOTE_PORT!") do (
    echo ERROR: Remote port must be numeric.
    exit /b 1
)

rem ============================================================
rem Check required commands
rem ============================================================
where curl.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: curl.exe was not found in PATH.
    exit /b 1
)

where ssh.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: ssh.exe was not found in PATH.
    echo Install or enable the Windows OpenSSH Client.
    exit /b 1
)

where scp.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: scp.exe was not found in PATH.
    echo Install or enable the Windows OpenSSH Client.
    exit /b 1
)

rem ============================================================
rem 1. Automatically retrieve the local VS Code Commit ID
rem ============================================================
set "COMMIT_ID="

where code.cmd >nul 2>&1
if not errorlevel 1 (
    for /f "skip=1 tokens=* delims=" %%A in ('code --version 2^>nul') do (
        if not defined COMMIT_ID set "COMMIT_ID=%%A"
    )
)

rem Fallback if the code command is unavailable
if not defined COMMIT_ID (
    echo ERROR: Could not determine the VS Code commit ID automatically.
    echo Find it in VS Code under Help ^> About ^> Commit.
    set /p "COMMIT_ID=Enter Commit ID manually: "
)

if not defined COMMIT_ID (
    echo ERROR: No commit ID provided. Exiting.
    exit /b 1
)

echo Target VS Code Commit ID: !COMMIT_ID!

rem ============================================================
rem 2. Set up paths and download URL
rem ============================================================
set "ARCHIVE_NAME=vscode-server-linux-x64.tar.gz"
set "DOWNLOAD_URL=https://update.code.visualstudio.com/commit:!COMMIT_ID!/server-linux-x64/stable"
set "LOCAL_TMP_DIR=%TEMP%\vscode-server-!COMMIT_ID!"
set "REMOTE_BIN_DIR=~/.vscode-server/bin/!COMMIT_ID!"

if not exist "!LOCAL_TMP_DIR!" (
    mkdir "!LOCAL_TMP_DIR!"
    if errorlevel 1 (
        echo ERROR: Could not create local directory:
        echo !LOCAL_TMP_DIR!
        exit /b 1
    )
)

rem ============================================================
rem 3. Download the server archive if it is not already cached
rem ============================================================
if not exist "!LOCAL_TMP_DIR!\!ARCHIVE_NAME!" (
    echo Downloading VS Code Server archive...

    curl.exe --fail --location ^
        "!DOWNLOAD_URL!" ^
        --output "!LOCAL_TMP_DIR!\!ARCHIVE_NAME!"

    if errorlevel 1 (
        echo ERROR: Failed to download the VS Code Server archive.
        exit /b 1
    )
) else (
    echo Found cached copy of the server archive locally.
)

rem ============================================================
rem 4. Create the target directory on the remote server
rem ============================================================
echo Creating remote directories...

ssh.exe -p "!REMOTE_PORT!" ^
    "!REMOTE_USER!@!REMOTE_HOST!" ^
    "mkdir -p !REMOTE_BIN_DIR!"

if errorlevel 1 (
    echo ERROR: Failed to create the remote directory.
    exit /b 1
)

rem ============================================================
rem 5. Copy the archive to the remote server
rem Note: scp uses uppercase -P for the port.
rem ============================================================
echo Transferring the server archive via SCP...

scp.exe -P "!REMOTE_PORT!" ^
    "!LOCAL_TMP_DIR!\!ARCHIVE_NAME!" ^
    "!REMOTE_USER!@!REMOTE_HOST!:!REMOTE_BIN_DIR!/"

if errorlevel 1 (
    echo ERROR: Failed to transfer the archive.
    exit /b 1
)

rem ============================================================
rem 6. Extract the server payload and remove the archive
rem ============================================================
echo Extracting files on the remote server...

ssh.exe -p "!REMOTE_PORT!" ^
    "!REMOTE_USER!@!REMOTE_HOST!" ^
    "cd !REMOTE_BIN_DIR! && tar -xzf !ARCHIVE_NAME! --strip-components=1 && rm !ARCHIVE_NAME! && touch ~/.vscode-server/vscode-cli-${COMMIT_ID}.tar.gz.done"

if errorlevel 1 (
    echo ERROR: Failed to extract the VS Code Server archive.
    exit /b 1
)

echo.
echo Success! VS Code Server was deployed to !REMOTE_HOST!.
echo You can now connect using the VS Code Remote - SSH extension.
exit /b 0

rem ============================================================
rem Usage
rem ============================================================
:usage_error
echo.
call :show_usage
exit /b 1

:usage
call :show_usage
exit /b 0

:show_usage
echo Usage:
echo   %~nx0 -u REMOTE_USER -h REMOTE_HOST [-p REMOTE_PORT]
echo.
echo Required:
echo   -u    Remote SSH user
echo   -h    Remote SSH host or IP address
echo.
echo Optional:
echo   -p    Remote SSH port; defaults to 22
echo   /?    Display this help
echo.
echo Examples:
echo   %~nx0 -u ubuntu -h myserver.example.com
echo   %~nx0 -u ubuntu -h myserver.example.com -p 2222
exit /b 0