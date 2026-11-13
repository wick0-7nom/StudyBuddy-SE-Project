@echo off
title Study Buddy - Run App
cd /d "%~dp0"

where flutter >nul 2>&1
if errorlevel 1 (
    echo Flutter not found. Run setup.bat first after installing Flutter.
    pause
    exit /b 1
)

if not exist "android\" (
    echo android folder missing. Run setup.bat first.
    pause
    exit /b 1
)

echo Starting Study Buddy...
echo Tip: Start an Android emulator in Android Studio first, or plug in your phone.
echo.
flutter run
pause
