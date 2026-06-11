# Run Flutter with China mirrors (pub + Flutter storage).
# Usage: .\run_flutter.ps1 run
#        .\run_flutter.ps1 run -d emulator-5554
#        .\run_flutter.ps1 pub get
$flutterBin = "F:\flutter_sdk\flutter\bin\flutter.bat"
if (-not (Test-Path $flutterBin)) {
    Write-Error "Flutter not found at $flutterBin. Install Flutter or update this path."
    exit 1
}

$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

function Suppress-AndroidNoiseLogs {
    $adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    if (-not (Test-Path $adb)) {
        $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
        if ($adbCmd) { $adb = $adbCmd.Source } else { return }
    }
    & $adb shell setprop log.tag.EGL_emulation SUPPRESS 2>$null
    & $adb shell setprop log.tag.EGL_emulation_app_time_stats SUPPRESS 2>$null
}

Write-Host "Using China mirrors: pub.flutter-io.cn / storage.flutter-io.cn" -ForegroundColor Cyan
if ($args.Count -gt 0 -and $args[0] -eq 'run') {
    Suppress-AndroidNoiseLogs
}
& $flutterBin @args
