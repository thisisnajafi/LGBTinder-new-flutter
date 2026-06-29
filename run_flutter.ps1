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

# Android emulator noise (EGL frame stats, GPU, etc.)
$script:LogNoisePattern = '(?i)(EGL_emulation|app_time_stats|libEGL\b|OpenGLRenderer|Choreographer|gralloc|ranchu|Goldfish\b|HWUI\b|SurfaceSyncer|FrameEvents|updateAcquireFence|ViewPostIme pointer|mali\.instrumentation)'

function Get-AdbPath {
    $adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $adb) { return $adb }
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) { return $adbCmd.Source }
    return $null
}

function Suppress-AndroidNoiseLogs {
    $adb = Get-AdbPath
    if (-not $adb) { return }

    & $adb wait-for-device 2>$null
    foreach ($tag in @(
            'EGL_emulation',
            'EGL_emulation_app_time_stats',
            'libEGL',
            'OpenGLRenderer',
            'Choreographer',
            'HWUI',
            'gralloc',
            'Goldfish'
        )) {
        & $adb shell setprop "log.tag.$tag" SUPPRESS 2>$null
    }
    & $adb logcat -P "EGL_emulation:S libEGL:S OpenGLRenderer:S Choreographer:S HWUI:S gralloc:S *:I" 2>$null
    & $adb logcat -c 2>$null
}

function Test-LogNoiseLine {
    param([string]$Line)
    if ([string]::IsNullOrEmpty($Line)) { return $false }
    return $Line -match $script:LogNoisePattern
}

function Invoke-FlutterDirect {
    param([string[]]$FlutterArgs)
    & $flutterBin @FlutterArgs
    exit $LASTEXITCODE
}

function Invoke-FlutterRunQuiet {
    param([string[]]$FlutterArgs)

    Suppress-AndroidNoiseLogs

    $argText = ($FlutterArgs | ForEach-Object {
            $escaped = $_ -replace '"', '\"'
            if ($escaped -match '\s') { "`"$escaped`"" } else { $escaped }
        }) -join ' '

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = "/c `"$flutterBin`" $argText"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardInput = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $process.StandardInput.AutoFlush = $true

    $stdoutTask = [System.Threading.Tasks.Task]::Run([System.Action]{
            try {
                while (-not $process.StandardOutput.EndOfStream) {
                    $line = $process.StandardOutput.ReadLine()
                    if ($null -eq $line) { break }
                    if (-not (Test-LogNoiseLine $line)) {
                        [Console]::Out.WriteLine($line)
                    }
                }
            } catch {}
        })

    $stderrTask = [System.Threading.Tasks.Task]::Run([System.Action]{
            try {
                while (-not $process.StandardError.EndOfStream) {
                    $line = $process.StandardError.ReadLine()
                    if ($null -eq $line) { break }
                    if (-not (Test-LogNoiseLine $line)) {
                        [Console]::Error.WriteLine($line)
                    }
                }
            } catch {}
        })

    $stdinTask = [System.Threading.Tasks.Task]::Run([System.Action]{
            try {
                while (-not $process.HasExited) {
                    if ([Console]::KeyAvailable) {
                        $key = [Console]::ReadKey($true)
                        if ($key.Key -eq 'C' -and ($key.Modifiers -band [ConsoleModifiers]::Control)) {
                            try { $process.Kill() } catch {}
                            break
                        }
                        $char = $key.KeyChar
                        if ($char -ne [char]0) {
                            $process.StandardInput.Write($char)
                        }
                    }
                    Start-Sleep -Milliseconds 15
                }
            } catch {}
        })

    $process.WaitForExit()
    try { $stdoutTask.Wait(2000) } catch {}
    try { $stderrTask.Wait(2000) } catch {}
    try { $stdinTask.Wait(200) } catch {}
    exit $process.ExitCode
}

Write-Host "Using China mirrors: pub.flutter-io.cn / storage.flutter-io.cn" -ForegroundColor Cyan

if ($args.Count -gt 0 -and $args[0] -eq 'run') {
    Invoke-FlutterRunQuiet -FlutterArgs $args
} else {
    Invoke-FlutterDirect -FlutterArgs $args
}
