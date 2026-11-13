@echo off
title Study Buddy - First Time Setup
echo ============================================
echo   Study Buddy - First Time Setup
echo ============================================
echo.

where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH.
    echo.
    echo Install Flutter from: https://docs.flutter.dev/get-started/install/windows
    echo Then add C:\src\flutter\bin to your PATH and restart this script.
    pause
    exit /b 1
)

echo [1/4] Flutter found:
flutter --version
echo.

cd /d "%~dp0"

echo [2/4] Creating Android/iOS platform files...
flutter create . --org com.studybuddy --project-name study_buddy
if errorlevel 1 (
    echo [ERROR] flutter create failed.
    pause
    exit /b 1
)
echo.

echo [3/4] Installing packages...
flutter pub get
if errorlevel 1 (
    echo [ERROR] flutter pub get failed.
    pause
    exit /b 1
)
echo.

echo [4/4] Running health check...
flutter doctor
echo.
echo ============================================
echo   Setup complete!
echo.
echo   Next: Double-click run.bat
echo   Or run: flutter run
echo ============================================
pause
