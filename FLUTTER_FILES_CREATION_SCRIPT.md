# Flutter Files Creation Guide

This document provides a script and instructions for creating all necessary Flutter files for the LGBTinder application.

## 📁 Directory Structure to Create

Run these commands in PowerShell from the `LGBTinder-flutter/lib` directory:

```powershell
# Core directories
New-Item -ItemType Directory -Force -Path "core/theme"
New-Item -ItemType Directory -Force -Path "core/constants"
New-Item -ItemType Directory -Force -Path "core/utils"
New-Item -ItemType Directory -Force -Path "core/widgets"

# Feature directories
New-Item -ItemType Directory -Force -Path "features/auth/data/models"
New-Item -ItemType Directory -Force -Path "features/auth/data/repositories"
New-Item -ItemType Directory -Force -Path "features/auth/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/auth/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/auth/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/auth/providers"

New-Item -ItemType Directory -Force -Path "features/onboarding/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/onboarding/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/onboarding/providers"

New-Item -ItemType Directory -Force -Path "features/profile/data/models"
New-Item -ItemType Directory -Force -Path "features/profile/data/repositories"
New-Item -ItemType Directory -Force -Path "features/profile/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/profile/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/profile/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/profile/providers"

New-Item -ItemType Directory -Force -Path "features/discover/data/models"
New-Item -ItemType Directory -Force -Path "features/discover/data/repositories"
New-Item -ItemType Directory -Force -Path "features/discover/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/discover/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/discover/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/discover/providers"

New-Item -ItemType Directory -Force -Path "features/matching/data/models"
New-Item -ItemType Directory -Force -Path "features/matching/data/repositories"
New-Item -ItemType Directory -Force -Path "features/matching/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/matching/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/matching/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/matching/providers"

New-Item -ItemType Directory -Force -Path "features/chat/data/models"
New-Item -ItemType Directory -Force -Path "features/chat/data/repositories"
New-Item -ItemType Directory -Force -Path "features/chat/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/chat/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/chat/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/chat/providers"

New-Item -ItemType Directory -Force -Path "features/calls/data/models"
New-Item -ItemType Directory -Force -Path "features/calls/data/repositories"
New-Item -ItemType Directory -Force -Path "features/calls/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/calls/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/calls/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/calls/providers"

New-Item -ItemType Directory -Force -Path "features/stories/data/models"
New-Item -ItemType Directory -Force -Path "features/stories/data/repositories"
New-Item -ItemType Directory -Force -Path "features/stories/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/stories/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/stories/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/stories/providers"

New-Item -ItemType Directory -Force -Path "features/notifications/data/models"
New-Item -ItemType Directory -Force -Path "features/notifications/data/repositories"
New-Item -ItemType Directory -Force -Path "features/notifications/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/notifications/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/notifications/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/notifications/providers"

New-Item -ItemType Directory -Force -Path "features/payments/data/models"
New-Item -ItemType Directory -Force -Path "features/payments/data/repositories"
New-Item -ItemType Directory -Force -Path "features/payments/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/payments/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/payments/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/payments/providers"

New-Item -ItemType Directory -Force -Path "features/settings/data/models"
New-Item -ItemType Directory -Force -Path "features/settings/data/repositories"
New-Item -ItemType Directory -Force -Path "features/settings/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/settings/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/settings/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/settings/providers"

New-Item -ItemType Directory -Force -Path "features/safety/data/models"
New-Item -ItemType Directory -Force -Path "features/safety/data/repositories"
New-Item -ItemType Directory -Force -Path "features/safety/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/safety/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/safety/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/safety/providers"

New-Item -ItemType Directory -Force -Path "features/feed/data/models"
New-Item -ItemType Directory -Force -Path "features/feed/data/repositories"
New-Item -ItemType Directory -Force -Path "features/feed/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/feed/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/feed/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/feed/providers"

New-Item -ItemType Directory -Force -Path "features/analytics/data/models"
New-Item -ItemType Directory -Force -Path "features/analytics/data/repositories"
New-Item -ItemType Directory -Force -Path "features/analytics/domain/use_cases"
New-Item -ItemType Directory -Force -Path "features/analytics/presentation/screens"
New-Item -ItemType Directory -Force -Path "features/analytics/presentation/widgets"
New-Item -ItemType Directory -Force -Path "features/analytics/providers"

# Shared directories
New-Item -ItemType Directory -Force -Path "shared/models"
New-Item -ItemType Directory -Force -Path "shared/services"
New-Item -ItemType Directory -Force -Path "shared/widgets"

# Routes directory
New-Item -ItemType Directory -Force -Path "routes"
```

## 📝 Files to Create

All files should be created with basic structure. See the detailed file templates in the following sections.

## 🚀 Quick Start

1. Navigate to `LGBTinder-flutter/lib`
2. Run the directory creation commands above
3. Use the file templates provided to create all necessary files
4. Each file should follow the structure outlined in `FLUTTER_PROJECT_STRUCTURE.md`

## 📚 Reference Documents

- `FLUTTER_PROJECT_STRUCTURE.md` - Complete folder structure
- `UI-DESIGN-SYSTEM.md` - Design tokens and styling guidelines
- `Enhanced-Flutter-UI-Document.md` - Screen-by-screen specifications

