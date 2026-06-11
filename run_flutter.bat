@echo off
REM Run Flutter with China mirrors (pub + Flutter storage).
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
set FLUTTER_BIN=F:\flutter_sdk\flutter\bin\flutter.bat
if not exist "%FLUTTER_BIN%" (
    echo Flutter not found at %FLUTTER_BIN%
    exit /b 1
)
echo Using China mirrors: pub.flutter-io.cn / storage.flutter-io.cn
if /I "%~1"=="run" (
    adb shell setprop log.tag.EGL_emulation SUPPRESS 2>nul
    adb shell setprop log.tag.EGL_emulation_app_time_stats SUPPRESS 2>nul
)
"%FLUTTER_BIN%" %*
