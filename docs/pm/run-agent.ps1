param([string]$Name,[string]$Model,[string]$PromptFile)
$r='E:\1 - laravel\1 - LGBTinder\lgbtindernew'
Set-Location $r
$env:HTTPS_PROXY='http://127.0.0.1:10808'; $env:HTTP_PROXY='http://127.0.0.1:10808'; $env:NO_PROXY='localhost,127.0.0.1,10.0.2.2'
$log="$r\docs\pm\logs\$Name.log"
"START $(Get-Date -Format o) model=$Model prompt=$PromptFile" | Out-File $log -Encoding utf8
$p = "Read the file $PromptFile in this repository completely and execute every instruction in it end to end. It is your full task specification."
& cursor-agent -p --force --trust --model $Model --output-format text $p *>> $log
"EXIT_CODE=$LASTEXITCODE" | Out-File $log -Append -Encoding utf8
"END_MARKER $(Get-Date -Format o)" | Out-File $log -Append -Encoding utf8

