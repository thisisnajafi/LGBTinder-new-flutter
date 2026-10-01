# Run or build one LGBTFinder flavor on Android.
# Examples:
#   .\scripts\flutter-flavor.ps1 -Flavor development
#   .\scripts\flutter-flavor.ps1 -Flavor production -Action appbundle
#   .\scripts\flutter-flavor.ps1 -Flavor staging -Action apk -DartDefine API_ORIGIN=https://staging.example.com
param(
    [ValidateSet("development", "staging", "production")]
    [string]$Flavor = "development",
    [ValidateSet("run", "apk", "appbundle")]
    [string]$Action = "run",
    [string]$DartDefine = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$target = "lib/main_$Flavor.dart"
$defineArgs = @()
if ($DartDefine) {
    $defineArgs = @("--dart-define=$DartDefine")
}

switch ($Action) {
    "run" { flutter run --flavor $Flavor --target $target @defineArgs }
    "apk" { flutter build apk --flavor $Flavor --target $target @defineArgs }
    "appbundle" { flutter build appbundle --flavor $Flavor --target $target @defineArgs }
}
