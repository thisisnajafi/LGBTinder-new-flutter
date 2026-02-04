@echo off
REM Run Flutter via junction path (no spaces) to avoid "F:\8 is not recognized" errors.
set FLUTTER_BIN=C:\Users\Abolfazl\flutter_sdk_link\flutter\bin\flutter.bat
if not exist "%FLUTTER_BIN%" (
    echo Flutter not found at %FLUTTER_BIN%
    echo Create junction: mklink /J "C:\Users\Abolfazl\flutter_sdk_link" "F:\8 - flutter sdk"
    exit /b 1
)
"%FLUTTER_BIN%" %*
