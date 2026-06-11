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

Write-Host "Using China mirrors: pub.flutter-io.cn / storage.flutter-io.cn" -ForegroundColor Cyan
& $flutterBin @args
