# Production Android build script for LGBTFinder (Windows).
# Usage: .\scripts\build_android.ps1 [-SkipTests] [-SkipAnalyze]
param(
    [switch]$SkipTests,
    [switch]$SkipAnalyze,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $ProjectRoot

$BuildStart = Get-Date
$SummaryDir = Join-Path $ProjectRoot "build\releases"
$ApkOut = Join-Path $SummaryDir "apk"
$AabOut = Join-Path $SummaryDir "aab"
New-Item -ItemType Directory -Force -Path $ApkOut, $AabOut | Out-Null

function Log([string]$Message) {
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "[$ts] $Message"
}

if (-not $env:PUB_HOSTED_URL) { $env:PUB_HOSTED_URL = "https://pub.dev" }
if (-not $env:FLUTTER_STORAGE_BASE_URL) { $env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com" }

Log "=== LGBTFinder Android Build ==="
Log "Project: $ProjectRoot"

$FlutterVersion = (flutter --version 2>$null | Select-Object -First 1)
Log "Flutter: $FlutterVersion"

Log "Step 1/7: Clean"
if ($Clean) {
    flutter clean
} else {
    Log "Skipping clean (pass -Clean to enable)"
}

Log "Step 2/7: Dependencies"
flutter pub get

$AnalyzeStatus = "skipped"
if (-not $SkipAnalyze) {
    Log "Step 3/7: Static analysis (lib/)"
    flutter analyze lib/ --no-fatal-infos --no-fatal-warnings
    if ($LASTEXITCODE -ne 0) {
        Log "WARN: flutter analyze reported issues (non-blocking)"
    }
    $AnalyzeStatus = "completed (see log)"
} else {
    Log "Step 3/7: Static analysis skipped"
}

$TestStatus = "skipped"
if (-not $SkipTests) {
    Log "Step 4/7: Unit tests"
    flutter test test/unit/
    if ($LASTEXITCODE -ne 0) { throw "Unit tests failed" }
    $TestStatus = "passed"
} else {
    Log "Step 4/7: Unit tests skipped"
}

Log "Step 5/7: Split release APKs (armeabi-v7a, arm64-v8a, x86_64)"
flutter build apk --release --split-per-abi
if ($LASTEXITCODE -ne 0) { throw "APK build failed" }

Log "Step 6/7: Release App Bundle"
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { throw "App Bundle build failed" }

Log "Step 7/7: Collect artifacts"
$ApkSrc = Join-Path $ProjectRoot "build\app\outputs\flutter-apk"
$AabSrc = Join-Path $ProjectRoot "build\app\outputs\bundle\release"

Get-ChildItem -Path $ApkSrc -Filter "app-*-release.apk" -ErrorAction SilentlyContinue | Copy-Item -Destination $ApkOut -Force
$UniversalApk = Join-Path $ApkSrc "app-release.apk"
if (Test-Path $UniversalApk) { Copy-Item $UniversalApk $ApkOut -Force }
Copy-Item (Join-Path $AabSrc "app-release.aab") $AabOut -Force

$Duration = [int]((Get-Date) - $BuildStart).TotalSeconds
$SummaryFile = Join-Path $SummaryDir "build-summary.txt"

@(
    "LGBTFinder Android Build Summary"
    "================================"
    "Timestamp: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')) UTC"
    "Flutter: $FlutterVersion"
    "Duration: ${Duration}s"
    "Analyze: $AnalyzeStatus"
    "Tests: $TestStatus"
    ""
    "APK artifacts:"
    (Get-ChildItem $ApkOut -ErrorAction SilentlyContinue | ForEach-Object { "  $($_.Name) ($([math]::Round($_.Length/1MB, 1)) MB)" })
    ""
    "AAB artifacts:"
    (Get-ChildItem $AabOut -ErrorAction SilentlyContinue | ForEach-Object { "  $($_.Name) ($([math]::Round($_.Length/1MB, 1)) MB)" })
) | Tee-Object -FilePath $SummaryFile

Log "Build complete in ${Duration}s"
Log "Artifacts: build\releases\apk\ and build\releases\aab\"
Log "Summary: $SummaryFile"
