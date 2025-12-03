# Font Setup Instructions

## Required Fonts

The LGBTinder app uses **Inter** as the primary font family (as specified in `UI-DESIGN-SYSTEM.md`).

## Download Fonts

### 1. Inter (Primary - Required)

Download from Google Fonts: https://fonts.google.com/specimen/Inter

**Required weights:**
- Regular (400)
- Medium (500)
- SemiBold (600)
- Bold (700)
- ExtraBold (800)
- Italic variants for each weight

**Download steps:**
1. Go to https://fonts.google.com/specimen/Inter
2. Click "Download family"
3. Extract the ZIP file
4. Copy the following files to `assets/fonts/Inter/`:
   - `Inter-Regular.ttf`
   - `Inter-Medium.ttf`
   - `Inter-SemiBold.ttf`
   - `Inter-Bold.ttf`
   - `Inter-ExtraBold.ttf`
   - `Inter-Italic.ttf`
   - `Inter-MediumItalic.ttf`
   - `Inter-SemiBoldItalic.ttf`
   - `Inter-BoldItalic.ttf`

### 2. Optional Fonts

The following fonts are optional but can be used for variety:

#### Nunito
- Download: https://fonts.google.com/specimen/Nunito
- Place in: `assets/fonts/Nunito/`

#### Urbanist
- Download: https://fonts.google.com/specimen/Urbanist
- Place in: `assets/fonts/Urbanist/`

#### Poppins
- Download: https://fonts.google.com/specimen/Poppins
- Place in: `assets/fonts/Poppins/`

## Directory Structure

Create the following directory structure:

```
lgbtindernew/
└── assets/
    └── fonts/
        ├── Inter/
        │   ├── Inter-Regular.ttf
        │   ├── Inter-Medium.ttf
        │   ├── Inter-SemiBold.ttf
        │   ├── Inter-Bold.ttf
        │   ├── Inter-ExtraBold.ttf
        │   ├── Inter-Italic.ttf
        │   ├── Inter-MediumItalic.ttf
        │   ├── Inter-SemiBoldItalic.ttf
        │   └── Inter-BoldItalic.ttf
        ├── Nunito/ (optional)
        ├── Urbanist/ (optional)
        └── Poppins/ (optional)
```

## Quick Setup Script

### Windows PowerShell

```powershell
# Create directories
New-Item -ItemType Directory -Force -Path "assets\fonts\Inter"
New-Item -ItemType Directory -Force -Path "assets\fonts\Nunito"
New-Item -ItemType Directory -Force -Path "assets\fonts\Urbanist"
New-Item -ItemType Directory -Force -Path "assets\fonts\Poppins"

Write-Host "Directories created. Please download fonts from Google Fonts and place them in the respective folders."
Write-Host "Inter (Required): https://fonts.google.com/specimen/Inter"
Write-Host "Nunito (Optional): https://fonts.google.com/specimen/Nunito"
Write-Host "Urbanist (Optional): https://fonts.google.com/specimen/Urbanist"
Write-Host "Poppins (Optional): https://fonts.google.com/specimen/Poppins"
```

### macOS/Linux

```bash
# Create directories
mkdir -p assets/fonts/Inter
mkdir -p assets/fonts/Nunito
mkdir -p assets/fonts/Urbanist
mkdir -p assets/fonts/Poppins

echo "Directories created. Please download fonts from Google Fonts and place them in the respective folders."
echo "Inter (Required): https://fonts.google.com/specimen/Inter"
echo "Nunito (Optional): https://fonts.google.com/specimen/Nunito"
echo "Urbanist (Optional): https://fonts.google.com/specimen/Urbanist"
echo "Poppins (Optional): https://fonts.google.com/specimen/Poppins"
```

## Using Fonts in Code

After adding fonts, update `lib/core/theme/typography.dart` to use the Inter font:

```dart
static const TextStyle h1 = TextStyle(
  fontFamily: 'Inter',  // Add this
  fontSize: 28,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.2,
  height: 1.2,
);
```

Or update `lib/core/theme/app_theme.dart` to set Inter as the default font:

```dart
static ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',  // Add this
    // ... rest of theme
  );
}
```

## Verification

After adding fonts, run:

```bash
flutter pub get
flutter clean
flutter pub get
```

Then verify fonts are loaded by checking the app's text rendering.

## Notes

- **Inter is the primary font** as specified in the design system
- Other fonts (Nunito, Urbanist, Poppins) are optional
- If you don't add the optional fonts, comment them out in `pubspec.yaml`
- Font files should be in `.ttf` or `.otf` format
- Make sure font file names match exactly what's specified in `pubspec.yaml`

