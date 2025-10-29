@echo off
:: Check for admin rights, if not, relaunch script as admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

setlocal enabledelayedexpansion

:: Prompt user to input file or folder path
set /p filepath=Enter the file or folder path to force delete:

:: Function to delete file or folder
:delete_path
echo Attempting to delete "%filepath%" ...
rmdir /s /q "%filepath%" 2>nul
del /f /q "%filepath%" 2>nul

if exist "%filepath%" (
    echo Deletion failed. Attempting to find and kill processes locking the file/folder...

    :: Use handle.exe to find processes locking the file/folder and kill them
    where handle.exe >nul 2>&1
    if errorlevel 1 (
        echo handle.exe not found. Please download from Sysinternals and place it in your PATH.
    ) else (
        for /f "tokens=2 delims=:" %%a in ('handle.exe -accepteula "%filepath%" ^| findstr "pid:"') do (
            set "pid=%%a"
            setlocal enabledelayedexpansion
            rem Remove all non-digit characters from pid
            for /f "delims=0123456789" %%x in ("%%a") do set "pid=%%a"
            set "pid=!pid: =!"
            for /f "tokens=* delims=0123456789" %%x in ("!pid!") do set "pid=!pid:%%x=!"
            if defined pid (
                echo Killing process ID !pid! locking the file...
                tasklist /FI "PID eq !pid!" 2>NUL | find /I "!pid!" >NUL
                if not errorlevel 1 (
                    taskkill /PID !pid! /F 2>NUL
                ) else (
                    echo Process ID !pid! not found, skipping.
                )
            )
            endlocal
        )
    )
    timeout /t 1 /nobreak >nul
    :: Try to delete again
    echo Attempting to delete "%filepath%" again ...

    rmdir /s /q "%filepath%" 2>nul
    del /f /q "%filepath%" 2>nul

    if exist "%filepath%" (
        echo Deletion still failed. Please check if the file/folder is still in use or path is correct.
    ) else (
        echo Deletion succeeded after killing locking processes.
    )
) else (
    echo Deletion succeeded.
)

pause
