# Font Setup Script for LGBTinder Flutter App
# This script creates the necessary directories for fonts

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LGBTinder Font Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create assets directory if it doesn't exist
if (-not (Test-Path "assets")) {
    New-Item -ItemType Directory -Path "assets" | Out-Null
    Write-Host "✓ Created assets directory" -ForegroundColor Green
}

# Create fonts directory if it doesn't exist
if (-not (Test-Path "assets\fonts")) {
    New-Item -ItemType Directory -Path "assets\fonts" | Out-Null
    Write-Host "✓ Created assets\fonts directory" -ForegroundColor Green
}

# Create font family directories
$fontFamilies = @("Inter", "Nunito", "Urbanist", "Poppins")

foreach ($fontFamily in $fontFamilies) {
    $fontPath = "assets\fonts\$fontFamily"
    if (-not (Test-Path $fontPath)) {
        New-Item -ItemType Directory -Path $fontPath | Out-Null
        Write-Host "✓ Created $fontPath directory" -ForegroundColor Green
    } else {
        Write-Host "→ $fontPath already exists" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Download Inter font (REQUIRED):" -ForegroundColor Yellow
Write-Host "   https://fonts.google.com/specimen/Inter" -ForegroundColor White
Write-Host "   - Click 'Download family'"
Write-Host "   - Extract and copy these files to assets\fonts\Inter\:"
Write-Host "     • Inter-Regular.ttf"
Write-Host "     • Inter-Medium.ttf"
Write-Host "     • Inter-SemiBold.ttf"
Write-Host "     • Inter-Bold.ttf"
Write-Host "     • Inter-ExtraBold.ttf"
Write-Host "     • Inter-Italic.ttf"
Write-Host "     • Inter-MediumItalic.ttf"
Write-Host "     • Inter-SemiBoldItalic.ttf"
Write-Host "     • Inter-BoldItalic.ttf"
Write-Host ""

Write-Host "2. Optional fonts (download if needed):" -ForegroundColor Yellow
Write-Host "   • Nunito: https://fonts.google.com/specimen/Nunito" -ForegroundColor White
Write-Host "   • Urbanist: https://fonts.google.com/specimen/Urbanist" -ForegroundColor White
Write-Host "   • Poppins: https://fonts.google.com/specimen/Poppins" -ForegroundColor White
Write-Host ""

Write-Host "3. After adding fonts, run:" -ForegroundColor Yellow
Write-Host "   flutter pub get" -ForegroundColor White
Write-Host "   flutter clean" -ForegroundColor White
Write-Host "   flutter pub get" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

