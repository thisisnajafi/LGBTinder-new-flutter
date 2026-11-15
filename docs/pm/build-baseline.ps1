Set-Location 'E:\1 - laravel\1 - LGBTinder\lgbtindernew'
$log='E:\1 - laravel\1 - LGBTinder\lgbtindernew\docs\pm\logs\build-baseline-debug.log'
'START '+(Get-Date -Format o) | Out-File $log -Encoding utf8
& F:\flutter_sdk\flutter\bin\flutter.bat build apk --debug --flavor development -t lib/main_development.dart --dart-define=API_ORIGIN=https://api.lgbtfinder.com --dart-define-from-file=dart_defines.json *>> $log
'EXIT_CODE='+$LASTEXITCODE | Out-File $log -Append -Encoding utf8
'END_MARKER '+(Get-Date -Format o) | Out-File $log -Append -Encoding utf8
