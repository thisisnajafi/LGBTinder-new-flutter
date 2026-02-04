# Run Flutter using the junction path (no spaces) to avoid "F:\8 is not recognized" build errors.
# Usage: .\run_flutter.ps1 run
#        .\run_flutter.ps1 build apk
#        .\run_flutter.ps1 pub get
$flutterBin = "C:\Users\Abolfazl\flutter_sdk_link\flutter\bin\flutter.bat"
if (-not (Test-Path $flutterBin)) {
    Write-Error "Flutter not found at $flutterBin. Create junction: New-Item -ItemType Junction -Path 'C:\Users\Abolfazl\flutter_sdk_link' -Target 'F:\8 - flutter sdk'"
    exit 1
}
& $flutterBin @args
