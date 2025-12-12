# Flutter Code Documentation Guide

## Overview

This document outlines code documentation standards for the LGBTinder Flutter application.

## Documentation Standards

### DartDoc Format

All public classes, methods, and properties should have DartDoc comments:

```dart
/// Get discovery profiles for swiping
///
/// Fetches profiles based on user preferences and filters.
/// Results are cached for 1 minute to reduce API calls.
///
/// [limit] Maximum number of profiles to return (default: 20)
/// [filters] Optional filters for age, location, interests, etc.
///
/// Returns a list of [DiscoveryProfile] objects
/// Throws [ApiException] if API call fails
Future<List<DiscoveryProfile>> getDiscoveryProfiles({
  int limit = 20,
  DiscoveryFilters? filters,
}) async {
  // Implementation
}
```

### Model Documentation

Models should document:
- Purpose and usage
- Required vs nullable fields
- JSON serialization behavior
- Type conversion handling

Example:

```dart
/// Message model for chat conversations
///
/// Handles serialization/deserialization from API responses.
/// Uses safe parsing to handle backend type inconsistencies.
///
/// **Required Fields:**
/// - [id], [senderId], [receiverId], [message], [createdAt]
///
/// **Nullable Fields:**
/// - [attachmentUrl], [metadata]
///
/// **Type Safety:**
/// - Handles string IDs (converts to int)
/// - Handles bool as int (0/1)
/// - Handles null values gracefully
class Message {
  /// Message ID from backend
  final int id;
  
  /// Sender user ID
  final int senderId;
  
  /// Receiver user ID
  final int receiverId;
  
  /// Message content (can be empty for media-only messages)
  final String message;
  
  // ... rest of fields
}
```

### Service Documentation

Services should document:
- Purpose and responsibility
- API endpoints used
- Error handling
- Caching behavior

Example:

```dart
/// Service for chat-related API operations
///
/// Handles:
/// - Sending/receiving messages
/// - Chat history retrieval
/// - Read receipts
/// - Typing indicators
///
/// **Endpoints:**
/// - POST /api/chat/send
/// - GET /api/chat/history
/// - POST /api/chat/read
///
/// **Error Handling:**
/// - Throws [ApiException] for API errors
/// - Returns empty list on network errors
class ChatService {
  final ApiService _apiService;
  
  /// Send a message to another user
  ///
  /// [receiverId] ID of the user to send message to
  /// [message] Message content
  /// [messageType] Type of message (text, image, voice, video)
  ///
  /// Returns the created [Message] object
  /// Throws [ApiException] if sending fails
  Future<Message> sendMessage(
    int receiverId,
    String message, {
    String messageType = 'text',
  }) async {
    // Implementation
  }
}
```

### Widget Documentation

Widgets should document:
- Purpose and usage
- Required parameters
- Optional parameters
- State management

Example:

```dart
/// Profile card widget for discovery screen
///
/// Displays a user profile with:
/// - Profile image
/// - Name and age
/// - Bio
/// - Action buttons (like, dislike, superlike)
///
/// **Usage:**
/// ```dart
/// ProfileCard(
///   profile: discoveryProfile,
///   onLike: () => _handleLike(),
///   onDislike: () => _handleDislike(),
///   onSuperlike: () => _handleSuperlike(),
/// )
/// ```
class ProfileCard extends StatelessWidget {
  /// The profile to display
  final DiscoveryProfile profile;
  
  /// Callback when user likes the profile
  final VoidCallback onLike;
  
  /// Whether the card is in loading state
  final bool isLoading;
  
  // ... rest of properties
}
```

## Architecture Documentation

Document architecture decisions in `lib/core/architecture/`:

- `architecture_guide.dart` - Clean Architecture overview
- `widget_decomposition_guide.dart` - Widget decomposition patterns

## Feature Module README

Each feature should have a README.md:

```
lib/features/
├── chat/
│   ├── README.md              # Chat feature overview
│   ├── data/
│   ├── domain/
│   └── presentation/
├── discover/
│   ├── README.md              # Discovery feature overview
│   └── ...
```

### README Template

```markdown
# Feature Name

## Overview
Brief description of the feature.

## Architecture
- **Data Layer**: Models, repositories, services
- **Domain Layer**: Use cases, entities
- **Presentation Layer**: Screens, widgets, providers

## Key Components
- Component 1 - Description
- Component 2 - Description

## API Integration
- Endpoint: `/api/endpoint`
- Request format: ...
- Response format: ...

## State Management
Uses Riverpod for state management:
- `featureProvider` - Main state provider
- `featureServiceProvider` - Service provider

## Usage Example
```dart
final featureState = ref.watch(featureProvider);
```

## Dependencies
- Service A
- Service B
```

## Model-to-API Mapping

Document how Flutter models map to API responses:

```dart
/// Model-to-API Field Mapping
///
/// Backend Field → Flutter Field
/// - id → id (int)
/// - sender_id → senderId (int)
/// - receiver_id → receiverId (int)
/// - message → message (String)
/// - is_read → isRead (bool, handles 0/1)
/// - created_at → createdAt (DateTime)
///
/// **Type Conversions:**
/// - String IDs → int (via int.tryParse)
/// - Bool as int → bool (0 = false, 1 = true)
/// - Null values → defaults (0, '', false)
class Message {
  // Implementation
}
```

## Error Handling Documentation

Document error handling patterns:

```dart
/// Error Handling Strategy
///
/// 1. **Network Errors**: Retry with exponential backoff
/// 2. **API Errors**: Show user-friendly message
/// 3. **Validation Errors**: Display field-specific errors
/// 4. **Unknown Errors**: Log and show generic message
///
/// **Error Codes:**
/// - `FEATURE_NOT_AVAILABLE` → Show upgrade prompt
/// - `DAILY_LIMIT_REACHED` → Show limit message
/// - `PROFILE_PICTURE_REQUIRED` → Navigate to profile
```

## Testing Documentation

Document test coverage (see `TESTING_GUIDE.md`).

## Code Comments

### When to Comment

- **Complex business logic** - Explain why
- **Workarounds** - Document temporary fixes
- **Non-obvious code** - Clarify intent
- **API quirks** - Document backend inconsistencies

### When NOT to Comment

- Self-explanatory code
- Obvious variable names
- Standard Flutter patterns

### Comment Style

```dart
// Good: Explains why
// Cache for 1 minute to balance freshness with API load
final cached = await cacheService.getCached('key', fromJson);

// Bad: States the obvious
// Get cached data
final cached = await cacheService.getCached('key', fromJson);
```

## Documentation Tools

- **DartDoc** - Standard Dart documentation
- **dart format** - Code formatting
- **dart analyze** - Static analysis

## Maintenance

- Update documentation when code changes
- Review documentation during code reviews
- Keep examples up-to-date
- Remove outdated documentation

