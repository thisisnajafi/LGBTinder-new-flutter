# Flutter Project Setup - Complete Guide

This document provides a complete overview of the Flutter project structure and setup for the LGBTinder application.

## 📚 Documentation Files Created

1. **FLUTTER_PROJECT_STRUCTURE.md** - Complete folder structure with Clean Architecture
2. **ALL_FLUTTER_FILES_LIST.md** - Comprehensive list of all 300+ files to create
3. **FLUTTER_FILES_CREATION_SCRIPT.md** - PowerShell script for directory creation
4. **UI-DESIGN-SYSTEM.md** - Complete design system (colors, typography, animations)
5. **Enhanced-Flutter-UI-Document.md** - Screen-by-screen UI specifications

## 🏗️ Project Architecture

The project follows **Clean Architecture** principles with clear separation:

```
features/
├── [feature_name]/
│   ├── data/           # Data layer (API, models, repositories)
│   ├── domain/         # Business logic (use cases)
│   ├── presentation/   # UI layer (screens, widgets)
│   └── providers/      # State management (Riverpod)
```

## 📁 Key Directories

### Core
- `core/theme/` - Theme configuration, colors, typography
- `core/constants/` - App constants, API endpoints, animations
- `core/utils/` - Utility functions (validation, formatting, error handling)
- `core/widgets/` - Reusable UI components

### Features (14 main features)
1. **auth** - Authentication (login, register, OAuth, OTP)
2. **onboarding** - User onboarding flow
3. **profile** - User profile management
4. **discover** - Discovery and swiping interface
5. **matching** - Matches, likes, superlikes
6. **chat** - Messaging and group chats
7. **calls** - Voice and video calls
8. **stories** - Story creation and viewing
9. **notifications** - Push notifications
10. **payments** - Subscriptions and payments (Stripe, PayPal)
11. **settings** - App settings and preferences
12. **safety** - Reporting, blocking, emergency contacts
13. **feed** - Social feed with posts
14. **analytics** - User analytics

### Shared
- `shared/models/` - Shared data models
- `shared/services/` - Core services (API, storage, WebSocket)
- `shared/widgets/` - Shared UI components

### Routes
- `routes/` - Navigation configuration (go_router)

## 🎨 Design System

All UI components follow the design system defined in `UI-DESIGN-SYSTEM.md`:

- **Colors**: Dark and light mode palettes
- **Typography**: Complete type scale (H1-H3, Body, Caption, etc.)
- **Spacing**: 4px base unit system
- **Animations**: Standardized durations and curves
- **Components**: Reusable widget library

## 🔌 API Integration

The app integrates with the Laravel backend API. Key endpoints:

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/verify-otp` - OTP verification
- `POST /api/auth/google/callback` - Google OAuth

### Profile
- `GET /api/user` - Get user profile
- `PUT /api/profile` - Update profile
- `POST /api/profile/complete` - Complete profile

### Discovery
- `GET /api/matching/nearby-suggestions` - Get discovery profiles
- `POST /api/likes` - Like a profile
- `POST /api/superlikes` - Superlike a profile

### Chat
- `GET /api/chat/users` - Get chat list
- `GET /api/chat/history` - Get chat history
- `POST /api/chat/send` - Send message

### Payments
- `GET /api/subscriptions/plans` - Get subscription plans
- `POST /api/subscriptions/create-checkout` - Create checkout
- `GET /api/user/payments/history` - Payment history

See `lgbtinder-backend/routes/api.php` for complete API reference.

## 🚀 Setup Steps

### 1. Create Directory Structure

Run the PowerShell script from `FLUTTER_FILES_CREATION_SCRIPT.md`:

```powershell
cd "LGBTinder-flutter/lib"
# Run directory creation commands
```

### 2. Create Files

Use `ALL_FLUTTER_FILES_LIST.md` as a checklist to create all 300+ files.

### 3. Implement Core Theme

Start with `core/theme/` files:
- `app_theme.dart` - Main theme configuration
- `app_colors.dart` - Color definitions
- `typography.dart` - Text styles

### 4. Implement Shared Services

Create core services:
- `shared/services/api_service.dart` - HTTP client
- `shared/services/storage_service.dart` - Local storage
- `shared/services/websocket_service.dart` - Real-time communication

### 5. Implement Features

Follow this order:
1. **auth** - Authentication flow
2. **onboarding** - User onboarding
3. **profile** - Profile management
4. **discover** - Discovery interface
5. **matching** - Matches and likes
6. **chat** - Messaging
7. **payments** - Subscriptions
8. **settings** - Settings and preferences
9. Other features as needed

### 6. Setup Routing

Configure `routes/app_router.dart` with go_router:
- Define all routes
- Add route guards
- Setup deep linking

## 📦 Required Packages

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  go_router: ^12.1.0
  cached_network_image: ^3.3.0
  photo_view: ^0.14.0
  lottie: ^2.7.0
  animations: ^2.0.7
  http: ^1.1.0
  dio: ^5.3.0
  flutter_secure_storage: ^9.0.0
  image_picker: ^1.0.4
  image_cropper: ^5.0.0
  url_launcher: ^6.2.0
  permission_handler: ^11.0.0
  flutter_local_notifications: ^16.0.0
  flutter_dotenv: ^5.1.0
  intl: ^0.18.1
  uuid: ^4.1.0
  share_plus: ^7.2.0
```

## 🎯 Development Guidelines

### State Management
- Use **Riverpod** for all state management
- Create providers for each feature
- Use `ConsumerWidget` or `ConsumerStatefulWidget`

### API Calls
- Use repository pattern
- Implement use cases for business logic
- Handle errors gracefully
- Show loading states

### UI Components
- Follow design system from `UI-DESIGN-SYSTEM.md`
- Support both dark and light modes
- Ensure accessibility (WCAG AA)
- Use reusable widgets from `core/widgets/`

### Navigation
- Use go_router for navigation
- Define routes in `routes/app_router.dart`
- Support deep linking
- Handle authentication guards

## ✅ Checklist

### Phase 1: Foundation
- [ ] Create directory structure
- [ ] Setup theme system
- [ ] Create core widgets
- [ ] Setup API service
- [ ] Configure routing

### Phase 2: Authentication
- [ ] Implement auth screens
- [ ] Setup auth provider
- [ ] Integrate OAuth
- [ ] Handle token storage

### Phase 3: Core Features
- [ ] Profile management
- [ ] Discovery interface
- [ ] Matching system
- [ ] Chat functionality

### Phase 4: Advanced Features
- [ ] Payments integration
- [ ] Calls functionality
- [ ] Stories feature
- [ ] Analytics

### Phase 5: Polish
- [ ] Settings screens
- [ ] Safety features
- [ ] Notifications
- [ ] Error handling

## 📖 Reference Documents

1. **UI-DESIGN-SYSTEM.md** - Design tokens, colors, typography
2. **Enhanced-Flutter-UI-Document.md** - Screen specifications
3. **FLUTTER_PROJECT_STRUCTURE.md** - Complete folder structure
4. **ALL_FLUTTER_FILES_LIST.md** - All files to create
5. **FLUTTER_FILES_CREATION_SCRIPT.md** - Setup scripts
6. **lgbtinder-backend/routes/api.php** - API endpoints

## 🐛 Troubleshooting

### Common Issues

1. **Import errors**: Ensure all directories are created
2. **Theme not working**: Check `app_theme.dart` configuration
3. **API errors**: Verify `api_endpoints.dart` URLs
4. **Navigation issues**: Check `app_router.dart` configuration

## 📞 Support

For questions or issues:
1. Check the relevant documentation file
2. Review API documentation in backend
3. Consult UI design system for styling
4. Reference screen specifications for layout

---

**Last Updated**: 2024  
**Version**: 1.0  
**Status**: Ready for Development

