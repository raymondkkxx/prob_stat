@echo off
@chcp 65001 >nul
setlocal EnableDelayedExpansion

:: 自动切换到脚本所在的当前文件夹
cd /d "%~dp0"

echo =================================================================
echo [WARNING] This script will erase all Git commit history and force-push 
echo           the current working directory as the new "First commit".
echo Target Directory : %CD%
echo =================================================================
echo.

:: 检查是否存在 Git 仓库
if not exist ".git" (
    echo [ERROR] No .git folder found in this directory.
    echo Please run this script from inside an existing Git repository.
    goto :FAIL
)

:: 自动获取当前分支名称，默认回退为 main
set "BRANCH="
for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do set "BRANCH=%%i"
if "!BRANCH!"=="" set "BRANCH=main"

:: 自动获取当前的 remote origin 地址
set "REPO_URL="
for /f "tokens=*" %%i in ('git remote get-url origin 2^>nul') do set "REPO_URL=%%i"

if "!REPO_URL!"=="" (
    echo [WARNING] Remote 'origin' is not configured.
    set /p "REPO_URL=Enter remote repository URL: "
    if "!REPO_URL!"=="" (
        echo [ERROR] Remote URL is required.
        goto :FAIL
    )
    git remote add origin !REPO_URL!
)

echo Remote Repository: !REPO_URL!
echo Target Branch    : !BRANCH!
echo.

set /p "CONFIRM=Are you sure you want to overwrite remote history? (Type Y to confirm, any other key to cancel): "
if /i not "!CONFIRM!"=="Y" (
    echo [INFO] Operation aborted by user.
    goto :END
)

echo.
echo [INFO] Creating orphan branch with clean history...
git checkout --orphan temp_first_commit
if errorlevel 1 (
    echo [ERROR] Failed to create orphan branch.
    goto :FAIL
)

echo [INFO] Staging all files...
git add -A

echo.
echo ========================= Staged Files =========================
git -c color.status=always status --short
echo =================================================================
echo.

set "COMMIT_MSG="
set /p "COMMIT_MSG=Enter commit message (Press Enter for 'First commit'): "
if "!COMMIT_MSG!"=="" (
    set "COMMIT_MSG=First commit"
)

echo.
echo [INFO] Committing changes: "!COMMIT_MSG!"...
git commit -m "!COMMIT_MSG!"
if errorlevel 1 (
    echo [ERROR] Commit failed. Ensure user.name and user.email are configured.
    goto :FAIL
)

echo [INFO] Rebasing branch pointer to !BRANCH!...
git branch -D !BRANCH! >nul 2>&1
git branch -m !BRANCH!

echo [INFO] Force-pushing to remote branch (!BRANCH!)...
git push -f -u origin !BRANCH!
if errorlevel 1 (
    echo.
    echo [ERROR] Git push failed. Please verify branch protection and SSH permissions.
    goto :FAIL
)

echo.
echo [SUCCESS] History cleared. Working directory pushed as first commit.
goto :END

:FAIL
echo.
echo [FAILURE] Script terminated with errors.

:END
echo.
pause