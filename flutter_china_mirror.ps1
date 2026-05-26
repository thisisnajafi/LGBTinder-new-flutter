# Flutter China Mirror + Pub Commands Runner
# Sets China mirror env vars and runs selected flutter/pub workflows.

$ErrorActionPreference = "Stop"

function Set-ChinaMirrors {
    $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
    $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

    Write-Host ""
    Write-Host "China mirrors enabled:" -ForegroundColor Green
    Write-Host "  PUB_HOSTED_URL           = $($env:PUB_HOSTED_URL)"
    Write-Host "  FLUTTER_STORAGE_BASE_URL = $($env:FLUTTER_STORAGE_BASE_URL)"
    Write-Host ""
}

function Invoke-FlutterCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    Write-Host ""
    Write-Host ">> $Label" -ForegroundColor Cyan
    Write-Host "   flutter $($Arguments -join ' ')" -ForegroundColor DarkGray

    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Failed: $Label (exit code $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

function Get-BuildTarget {
    Write-Host ""
    Write-Host "Select build target:" -ForegroundColor Yellow
    Write-Host "  1) APK (debug)"
    Write-Host "  2) APK (release)"
    Write-Host "  3) App Bundle (release)"
    Write-Host "  4) Windows (release)"
    Write-Host "  5) Web (release)"
    Write-Host "  6) iOS (release, macOS only)"
    Write-Host ""

    $choice = Read-Host "Enter choice [1-6] (default: 2)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "2" }

    switch ($choice) {
        "1" { return @{ Label = "Build APK (debug)"; Args = @("build", "apk", "--debug") } }
        "2" { return @{ Label = "Build APK (release)"; Args = @("build", "apk", "--release") } }
        "3" { return @{ Label = "Build App Bundle (release)"; Args = @("build", "appbundle", "--release") } }
        "4" { return @{ Label = "Build Windows (release)"; Args = @("build", "windows", "--release") } }
        "5" { return @{ Label = "Build Web (release)"; Args = @("build", "web", "--release") } }
        "6" { return @{ Label = "Build iOS (release)"; Args = @("build", "ios", "--release") } }
        default {
            Write-Host "Invalid choice. Using APK (release)." -ForegroundColor Yellow
            return @{ Label = "Build APK (release)"; Args = @("build", "apk", "--release") }
        }
    }
}

function Get-RunOptions {
    Write-Host ""
    Write-Host "Run options (press Enter to skip each prompt):" -ForegroundColor Yellow

    $device = Read-Host "Device ID or name (optional)"
    $flavor = Read-Host "Flavor (optional)"
    $dartDefine = Read-Host "Extra dart-define, e.g. API_URL=https://example.com (optional)"

    $args = @("run")
    if (-not [string]::IsNullOrWhiteSpace($device)) { $args += @("-d", $device.Trim()) }
    if (-not [string]::IsNullOrWhiteSpace($flavor)) { $args += @("--flavor", $flavor.Trim()) }
    if (-not [string]::IsNullOrWhiteSpace($dartDefine)) { $args += @("--dart-define=$($dartDefine.Trim())") }

    return @{
        Label = "Run app"
        Args  = $args
    }
}

function Show-Menu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  LGBTinder Flutter - China Mirror Tool" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Quick presets:" -ForegroundColor Yellow
    Write-Host "  1)  pub get"
    Write-Host "  2)  clean"
    Write-Host "  3)  clean -> pub get"
    Write-Host "  4)  clean -> pub get -> build"
    Write-Host "  5)  clean -> pub get -> run"
    Write-Host "  6)  build only"
    Write-Host "  7)  run only"
    Write-Host "  8)  pub upgrade"
    Write-Host "  9)  pub outdated"
    Write-Host ""
    Write-Host "Custom combination (choose steps in order):" -ForegroundColor Yellow
    Write-Host " 10) Pick: clean / get / build / run"
    Write-Host ""
    Write-Host "  0) Exit"
    Write-Host ""
}

function Invoke-Workflow {
    param(
        [bool]$DoClean = $false,
        [bool]$DoGet = $false,
        [bool]$DoBuild = $false,
        [bool]$DoRun = $false,
        [bool]$UseUpgrade = $false
    )

    if ($DoClean) {
        Invoke-FlutterCommand -Label "Clean project" -Arguments @("clean")
    }

    if ($UseUpgrade) {
        Invoke-FlutterCommand -Label "Upgrade dependencies" -Arguments @("pub", "upgrade")
    }
    elseif ($DoGet) {
        Invoke-FlutterCommand -Label "Get dependencies" -Arguments @("pub", "get")
    }

    if ($DoBuild) {
        $target = Get-BuildTarget
        Invoke-FlutterCommand -Label $target.Label -Arguments $target.Args
    }

    if ($DoRun) {
        $run = Get-RunOptions
        Invoke-FlutterCommand -Label $run.Label -Arguments $run.Args
    }
}

function Get-CustomCombination {
    Write-Host ""
    Write-Host "Toggle each step (y/n). Steps run in order: clean -> get -> build -> run" -ForegroundColor Yellow

    $doClean = (Read-Host "Include clean? [y/N]").Trim().ToLower() -in @("y", "yes")
    $doGet = (Read-Host "Include pub get? [Y/n]").Trim().ToLower()
    if ([string]::IsNullOrWhiteSpace($doGet) -or $doGet -in @("y", "yes")) { $doGet = $true } else { $doGet = $false }

    $doBuild = (Read-Host "Include build? [y/N]").Trim().ToLower() -in @("y", "yes")
    $doRun = (Read-Host "Include run? [y/N]").Trim().ToLower() -in @("y", "yes")

    if (-not ($doClean -or $doGet -or $doBuild -or $doRun)) {
        Write-Host "No steps selected." -ForegroundColor Yellow
        return
    }

    Invoke-Workflow -DoClean $doClean -DoGet $doGet -DoBuild $doBuild -DoRun $doRun
}

# --- Main ---

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "flutter is not on PATH. Install Flutter or add it to PATH first." -ForegroundColor Red
    exit 1
}

Set-ChinaMirrors

Write-Host "Project: $ScriptDir" -ForegroundColor DarkGray

do {
    Show-Menu
    $selection = Read-Host "Select an option"

    switch ($selection) {
        "1"  { Invoke-Workflow -DoGet $true }
        "2"  { Invoke-Workflow -DoClean $true }
        "3"  { Invoke-Workflow -DoClean $true -DoGet $true }
        "4"  { Invoke-Workflow -DoClean $true -DoGet $true -DoBuild $true }
        "5"  { Invoke-Workflow -DoClean $true -DoGet $true -DoRun $true }
        "6"  { Invoke-Workflow -DoBuild $true }
        "7"  { Invoke-Workflow -DoRun $true }
        "8"  { Invoke-Workflow -UseUpgrade $true }
        "9"  {
            Invoke-FlutterCommand -Label "Check outdated packages" -Arguments @("pub", "outdated")
        }
        "10" { Get-CustomCombination }
        "0"  {
            Write-Host ""
            Write-Host "Done." -ForegroundColor Green
            break
        }
        default {
            Write-Host "Invalid option. Choose 0-10." -ForegroundColor Yellow
        }
    }

    if ($selection -ne "0") {
        Write-Host ""
        Write-Host "Workflow finished successfully." -ForegroundColor Green
        $again = Read-Host "Run another workflow? [Y/n]"
        if ($again.Trim().ToLower() -in @("n", "no")) {
            break
        }
    }
} while ($selection -ne "0")
