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
    call :SuppressAndroidNoise
)
"%FLUTTER_BIN%" %*
exit /b %ERRORLEVEL%

:SuppressAndroidNoise
where adb >nul 2>&1
if errorlevel 1 exit /b 0
adb wait-for-device >nul 2>&1
adb shell setprop log.tag.EGL_emulation SUPPRESS >nul 2>&1
adb shell setprop log.tag.EGL_emulation_app_time_stats SUPPRESS >nul 2>&1
adb shell setprop log.tag.libEGL SUPPRESS >nul 2>&1
adb shell setprop log.tag.OpenGLRenderer SUPPRESS >nul 2>&1
adb shell setprop log.tag.Choreographer SUPPRESS >nul 2>&1
adb logcat -P "EGL_emulation:S libEGL:S OpenGLRenderer:S Choreographer:S" >nul 2>&1
adb logcat -c >nul 2>&1
exit /b 0
