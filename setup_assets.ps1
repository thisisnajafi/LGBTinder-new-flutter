# Asset Setup Script for LGBTinder Flutter App
# This script creates the necessary directories for images, lottie, and sounds

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LGBTinder Asset Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create main assets directory
if (-not (Test-Path "assets")) {
    New-Item -ItemType Directory -Path "assets" | Out-Null
    Write-Host "✓ Created assets directory" -ForegroundColor Green
}

# Create image directories
$imageDirs = @(
    "assets\images",
    "assets\images\logo",
    "assets\images\onboarding",
    "assets\images\placeholders",
    "assets\images\avatars",
    "assets\images\icons"
)

foreach ($dir in $imageDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "✓ Created $dir directory" -ForegroundColor Green
    } else {
        Write-Host "→ $dir already exists" -ForegroundColor Yellow
    }
}

# Create lottie directory
if (-not (Test-Path "assets\lottie")) {
    New-Item -ItemType Directory -Path "assets\lottie" | Out-Null
    Write-Host "✓ Created assets\lottie directory" -ForegroundColor Green
} else {
    Write-Host "→ assets\lottie already exists" -ForegroundColor Yellow
}

# Create sounds directory
if (-not (Test-Path "assets\sounds")) {
    New-Item -ItemType Directory -Path "assets\sounds" | Out-Null
    Write-Host "✓ Created assets\sounds directory" -ForegroundColor Green
} else {
    Write-Host "→ assets\sounds already exists" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Asset Requirements Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📸 IMAGES REQUIRED:" -ForegroundColor Yellow
Write-Host "  • Logo: assets\images\logo\logo.png" -ForegroundColor White
Write-Host "  • App Icon: assets\images\logo\app_icon.png" -ForegroundColor White
Write-Host "  • Splash: assets\images\splash\splash.png" -ForegroundColor White
Write-Host "  • Onboarding: 4 images in assets\images\onboarding\" -ForegroundColor White
Write-Host "  • Placeholders: 10+ images in assets\images\placeholders\" -ForegroundColor White
Write-Host ""
Write-Host "🎬 LOTTIE ANIMATIONS REQUIRED (25 files):" -ForegroundColor Yellow
Write-Host "  • Loading: 3 files" -ForegroundColor White
Write-Host "  • Success & Celebration: 4 files" -ForegroundColor White
Write-Host "  • Profile & Verification: 3 files" -ForegroundColor White
Write-Host "  • Empty States: 5 files" -ForegroundColor White
Write-Host "  • Error States: 3 files" -ForegroundColor White
Write-Host "  • Interactive Elements: 4 files" -ForegroundColor White
Write-Host "  • Premium Features: 3 files" -ForegroundColor White
Write-Host ""
Write-Host "🎵 SOUNDS (Optional):" -ForegroundColor Yellow
Write-Host "  • Notification sounds: 3-4 files" -ForegroundColor White
Write-Host "  • Interaction sounds: 3-4 files" -ForegroundColor White
Write-Host ""
Write-Host "📖 For complete list, see: ASSETS_REQUIREMENTS.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

