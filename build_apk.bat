@echo off
title Study Buddy - Build APK
cd /d "%~dp0"
flutter build apk --release
echo.
echo APK saved to: build\app\outputs\flutter-apk\app-release.apk
pause
