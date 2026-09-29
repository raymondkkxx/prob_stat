@echo off
setlocal EnableDelayedExpansion

set "TARGET_DIR=C:\Users\raymond\Desktop\prob_stat"
set "REPO_URL=git@github.com:raymondkkxx/prob_stat.git"
set "BRANCH=main"

cd /d "%TARGET_DIR%"
if errorlevel 1 (
    echo [ERROR] Target directory not found: %TARGET_DIR%
    goto :FAIL
)

if not exist ".git" (
    echo [INFO] Initializing new Git repository...
    git init
    git branch -M %BRANCH%
    git remote add origin %REPO_URL%
    echo [INFO] Syncing remote history...
    git fetch origin %BRANCH%
    if not errorlevel 1 (
        git pull origin %BRANCH% --allow-unrelated-histories --no-edit
    )
) else (
    git remote get-url origin >nul 2>&1
    if errorlevel 1 (
        echo [INFO] Adding remote origin...
        git remote add origin %REPO_URL%
    ) else (
        git remote set-url origin %REPO_URL%
    )
)

echo [INFO] Staging all changes...
git add -A

echo.
echo ==================== Staged Changes ====================
git -c color.status=always status --short
echo =======================================================
echo.

git diff --cached --quiet
if errorlevel 1 (
    set "COMMIT_MSG="
    set /p "COMMIT_MSG=Enter commit message (Press Enter for default timestamp): "
    if "!COMMIT_MSG!"=="" (
        set "COMMIT_MSG=Update: %date% %time%"
    )
    echo.
    echo [INFO] Committing changes: "!COMMIT_MSG!"...
    git commit -m "!COMMIT_MSG!"
    if errorlevel 1 (
        echo.
        echo [ERROR] Git commit failed Check git config user.name and user.email.
        goto :FAIL
    )
    echo [INFO] Pushing changes to GitHub...
    git push -u origin %BRANCH%
    if errorlevel 1 (
        echo.
        echo [ERROR] Git push failed Check SSH keys and repo permissions.
        goto :FAIL
    )
) else (
    echo [INFO] Working tree clean. No changes to commit.
)

echo.
echo [SUCCESS] Operation finished.
goto :END

:FAIL
echo.
echo [FAILURE] Script terminated with errors.

:END
echo.
pause
