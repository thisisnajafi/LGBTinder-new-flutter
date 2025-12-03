# API Integration Tasks - LGBTinder Flutter App

## 📋 Overview

This document outlines all tasks required to connect the LGBTinder Flutter app to the backend API.

**Base URL**: `http://lg.abolfazlnajafi.com/api`  
**Authentication**: Bearer Token (stored in `flutter_secure_storage`)  
**Reference**: `LGBTinder_API_Postman_Collection_Updated.json`

---

## 🎯 Task Categories

### Phase 1: Core Infrastructure (Tasks 1-5)
Foundation setup for all API calls

### Phase 2: Authentication & Registration (Tasks 6-10)
User registration, login, email verification, profile completion

### Phase 3: Reference Data (Tasks 11-20)
Static data endpoints (countries, cities, genders, interests, etc.)

### Phase 4: User & Profile Management (Tasks 21-30)
User info, profile CRUD, image management

### Phase 5: Discovery & Matching (Tasks 31-34)
Profile discovery, matching algorithms, compatibility scores

### Phase 6: Likes & Superlikes (Tasks 35-40)
Like/dislike/superlike actions, matches, pending likes

### Phase 7: Chat & Messaging (Tasks 41-47)
Message sending, chat history, real-time WebSocket

### Phase 8: Notifications (Tasks 48-52)
Notification fetching, read status, unread counts

### Phase 9: Stories & Feeds (Tasks 53-59)
Stories upload/view, social feed posts, reactions, comments

### Phase 10: User Actions (Tasks 60-65)
Block, unblock, report, mute, favorites

### Phase 11: Payments & Subscriptions (Tasks 66-71)
Subscription plans, Stripe integration, payment processing

### Phase 12: Superlikes (Tasks 72-74)
Superlike pack purchases and management

### Phase 13: UI Integration (Tasks 75-92)
Connect all screens to APIs, error handling, loading states

---

## 📝 Detailed Task List

### 🔧 Phase 1: Core Infrastructure

#### Task 1: Set up Base HTTP Client
- [ ] Create Dio instance with base URL `http://lg.abolfazlnajafi.com/api`
- [ ] Configure interceptors:
  - [ ] Request interceptor: Add Bearer token from secure storage
  - [ ] Response interceptor: Handle errors, token refresh
  - [ ] Logging interceptor: Log requests/responses in debug mode
- [ ] Set default headers (Content-Type: application/json, Accept: application/json)
- [ ] Configure timeout settings (connectTimeout: 30s, receiveTimeout: 30s)
- [ ] Handle SSL certificate validation

**Files to Create/Modify:**
- `lib/shared/services/api_service.dart`
- `lib/core/network/dio_client.dart` (new)

---

#### Task 2: Implement API Response Models
- [ ] Create `ApiResponse<T>` generic model with:
  - [ ] `status: bool`
  - [ ] `message: String`
  - [ ] `data: T?`
- [ ] Create `ApiError` model with:
  - [ ] `code: int`
  - [ ] `message: String`
  - [ ] `errors: Map<String, List<String>>?`
- [ ] Implement JSON serialization (fromJson/toJson)
- [ ] Handle different response formats

**Files to Modify:**
- `lib/shared/models/api_response.dart`
- `lib/shared/models/api_error.dart`

---

#### Task 3: Create API Endpoints Constants
- [ ] Create `ApiEndpoints` class with all endpoint constants:
  - [ ] Authentication endpoints (`/auth/register`, `/auth/login-password`, etc.)
  - [ ] Reference data endpoints (`/countries`, `/cities`, `/genders`, etc.)
  - [ ] User endpoints (`/user`, `/profile`, etc.)
  - [ ] Matching endpoints (`/matching/*`, `/likes/*`)
  - [ ] Chat endpoints (`/chat/*`)
  - [ ] Notification endpoints (`/notifications/*`)
  - [ ] Stories & Feeds endpoints (`/stories/*`, `/feeds/*`)
  - [ ] Payment endpoints (`/stripe/*`, `/subscriptions/*`)
- [ ] Organize by feature modules
- [ ] Use string constants for maintainability

**Files to Modify:**
- `lib/core/constants/api_endpoints.dart`

---

#### Task 4: Implement Secure Token Storage
- [ ] Create `TokenStorageService` using `flutter_secure_storage`
- [ ] Methods:
  - [ ] `saveAuthToken(String token)`
  - [ ] `getAuthToken() -> Future<String?>`
  - [ ] `saveProfileCompletionToken(String token)`
  - [ ] `getProfileCompletionToken() -> Future<String?>`
  - [ ] `clearAllTokens()`
- [ ] Handle token expiration
- [ ] Auto-refresh tokens when expired

**Files to Create:**
- `lib/shared/services/token_storage_service.dart`

---

#### Task 5: Create API Service Base Class
- [ ] Create base `ApiService` class with common methods:
  - [ ] `get<T>(String endpoint, {Map<String, dynamic>? queryParams})`
  - [ ] `post<T>(String endpoint, {Map<String, dynamic>? data})`
  - [ ] `put<T>(String endpoint, {Map<String, dynamic>? data})`
  - [ ] `delete<T>(String endpoint)`
  - [ ] `uploadFile(String endpoint, File file, {Map<String, dynamic>? fields})`
- [ ] Handle response parsing
- [ ] Handle errors consistently
- [ ] Return typed responses

**Files to Modify:**
- `lib/shared/services/api_service.dart`

---

### 🔐 Phase 2: Authentication & Registration

#### Task 6: Register User API
- [ ] Endpoint: `POST /auth/register`
- [ ] Request body: `{first_name, last_name, email, password, referral_code?}`
- [ ] Response: `{status, message, data: {user_id, email, email_sent, resend_available_at}}`
- [ ] Handle success → Navigate to Email Verification
- [ ] Handle errors (email exists, validation errors)

**Files to Create:**
- `lib/features/auth/services/auth_service.dart`
- `lib/features/auth/models/register_request.dart`
- `lib/features/auth/models/register_response.dart`

**Screens to Connect:**
- `lib/screens/auth/register_screen.dart`

---

#### Task 7: Login with Password API
- [ ] Endpoint: `POST /auth/login-password`
- [ ] Request body: `{email, password, device_name}`
- [ ] Response: `{status, message, data: {user, token, user_state, profile_completed}}`
- [ ] Handle different user states:
  - [ ] `email_verification_required` → Navigate to Email Verification
  - [ ] `profile_completion_required` → Navigate to Profile Wizard
  - [ ] `ready_for_app` → Navigate to HomePage
- [ ] Save auth token to secure storage
- [ ] Handle invalid credentials

**Files to Modify:**
- `lib/features/auth/services/auth_service.dart`
- `lib/features/auth/models/login_request.dart`
- `lib/features/auth/models/login_response.dart`

**Screens to Connect:**
- `lib/screens/auth/login_screen.dart`

---

#### Task 8: Check User State API
- [ ] Endpoint: `POST /auth/check-user-state`
- [ ] Request body: `{email}`
- [ ] Response: `{status, message, data: {user_state, user_id, token?}}`
- [ ] Use for app launch to determine navigation
- [ ] Handle all user states

**Files to Modify:**
- `lib/features/auth/services/auth_service.dart`

**Screens to Connect:**
- `lib/pages/splash_page.dart`

---

#### Task 9: Verify Email Code API
- [ ] Endpoint: `POST /auth/send-verification`
- [ ] Request body: `{email, code}`
- [ ] Response: `{status, message, data: {user_id, token, profile_completion_required}}`
- [ ] Save profile_completion_token if needed
- [ ] Handle invalid/expired codes
- [ ] Implement resend code functionality

**Files to Modify:**
- `lib/features/auth/services/auth_service.dart`

**Screens to Connect:**
- `lib/screens/auth/email_verification_screen.dart`

---

#### Task 10: Complete Profile Registration API
- [ ] Endpoint: `POST /complete-registration`
- [ ] Headers: `Authorization: Bearer {profile_completion_token}`
- [ ] Request body: All profile fields (country_id, city_id, gender, birth_date, bio, height, weight, interests, etc.)
- [ ] Response: `{status, message, data: {user, token, profile_completed}}`
- [ ] Save full access token
- [ ] Navigate to Onboarding or HomePage

**Files to Modify:**
- `lib/features/auth/services/auth_service.dart`
- `lib/features/profile/services/profile_service.dart`

**Screens to Connect:**
- `lib/screens/auth/profile_wizard_screen.dart`

---

### 📚 Phase 3: Reference Data

#### Tasks 11-20: Reference Data APIs
All reference data endpoints follow similar patterns:

- [ ] **Task 11**: Get Countries (`GET /countries`)
- [ ] **Task 12**: Get Cities by Country (`GET /cities/country/{id}`)
- [ ] **Task 13**: Get Genders (`GET /genders`)
- [ ] **Task 14**: Get Jobs (`GET /jobs`)
- [ ] **Task 15**: Get Education Levels (`GET /education`)
- [ ] **Task 16**: Get Interests (`GET /interests`)
- [ ] **Task 17**: Get Languages (`GET /languages`)
- [ ] **Task 18**: Get Music Genres (`GET /music-genres`)
- [ ] **Task 19**: Get Relationship Goals (`GET /relation-goals`)
- [ ] **Task 20**: Get Preferred Genders (`GET /preferred-genders`)

**Implementation Notes:**
- Create `ReferenceDataService` with methods for each endpoint
- Cache reference data locally (SharedPreferences) to reduce API calls
- Create models for each data type (Country, City, Gender, etc.)
- Use Riverpod providers for state management

**Files to Create:**
- `lib/features/reference_data/services/reference_data_service.dart`
- `lib/features/reference_data/models/` (Country, City, Gender, etc.)
- `lib/features/reference_data/providers/reference_data_providers.dart`

**Screens to Connect:**
- Profile Wizard screens
- Profile Edit screen
- Filter screens

---

### 👤 Phase 4: User & Profile Management

#### Task 21: Get User Info API
- [ ] Endpoint: `GET /user`
- [ ] Response: User object with all details
- [ ] Use for displaying current user info
- [ ] Cache user data locally

**Files to Create:**
- `lib/features/user/services/user_service.dart`
- `lib/features/user/models/user_model.dart`

---

#### Task 22: Save OneSignal Player ID API
- [ ] Endpoint: `POST /user/onesignal-player`
- [ ] Request body: `{player_id}`
- [ ] Call after OneSignal initialization
- [ ] Update on app launch if changed

**Files to Modify:**
- `lib/features/user/services/user_service.dart`
- `lib/shared/services/notification_service.dart`

---

#### Task 23: Update Notification Preferences API
- [ ] Endpoint: `POST /user/notification-preferences`
- [ ] Request body: `{email_notifications, push_notifications, match_notifications, etc.}`
- [ ] Save preferences locally and sync with API

**Files to Modify:**
- `lib/features/user/services/user_service.dart`

**Screens to Connect:**
- `lib/screens/notification_settings_screen.dart`

---

#### Task 24: Get My Profile API
- [ ] Endpoint: `GET /profile`
- [ ] Response: Complete profile with images, interests, preferences
- [ ] Cache profile data
- [ ] Refresh on pull-to-refresh

**Files to Modify:**
- `lib/features/profile/services/profile_service.dart`

**Screens to Connect:**
- `lib/pages/profile_page.dart`

---

#### Task 25: Get User Profile API
- [ ] Endpoint: `GET /profile/{user_id}`
- [ ] Response: Other user's profile
- [ ] Use for Profile Detail Screen

**Files to Modify:**
- `lib/features/profile/services/profile_service.dart`

**Screens to Connect:**
- `lib/pages/discovery_page.dart` (on card tap)
- `lib/screens/profile/profile_detail_screen.dart`

---

#### Task 26: Update Profile API
- [ ] Endpoint: `POST /profile/update`
- [ ] Request body: `{profile_bio, height, weight, smoke, drink, gym, etc.}`
- [ ] Handle partial updates
- [ ] Optimistic UI updates

**Files to Modify:**
- `lib/features/profile/services/profile_service.dart`

**Screens to Connect:**
- `lib/screens/profile_edit_screen.dart`

---

#### Tasks 27-30: Image Management APIs
- [ ] **Task 27**: Upload Image (`POST /images/upload`) - Multipart form data
- [ ] **Task 28**: Delete Image (`DELETE /images/{id}`)
- [ ] **Task 29**: Reorder Images (`POST /images/reorder`) - `{image_order: [3,1,2,4]}`
- [ ] **Task 30**: Set Primary Image (`POST /images/{id}/set-primary`)

**Implementation Notes:**
- Use `image_picker` for selecting images
- Compress images before upload using `flutter_image_compress`
- Show upload progress
- Handle image upload errors

**Files to Create:**
- `lib/features/profile/services/image_service.dart`

**Screens to Connect:**
- `lib/screens/profile_edit_screen.dart`
- `lib/screens/auth/profile_wizard_screen.dart` (photo upload step)

---

### 🔍 Phase 5: Discovery & Matching

#### Task 31: Get Nearby Suggestions API
- [ ] Endpoint: `GET /matching/nearby-suggestions`
- [ ] Query params: `?latitude={lat}&longitude={lng}&distance={km}`
- [ ] Response: List of profile suggestions
- [ ] Use for Discovery Page card stack
- [ ] Implement pagination/infinite scroll

**Files to Create:**
- `lib/features/discover/services/discover_service.dart`
- `lib/features/discover/models/profile_suggestion.dart`

**Screens to Connect:**
- `lib/pages/discovery_page.dart`

---

#### Task 32: Get Advanced Matches API
- [ ] Endpoint: `GET /matching/advanced`
- [ ] Query params: Filters (age, distance, gender, interests)
- [ ] Response: Filtered profile suggestions
- [ ] Use when filters are applied

**Files to Modify:**
- `lib/features/discover/services/discover_service.dart`

**Screens to Connect:**
- `lib/pages/discovery_page.dart` (with filters)

---

#### Task 33: Get Compatibility Score API
- [ ] Endpoint: `GET /matching/compatibility-score?user_id={id}`
- [ ] Response: Compatibility percentage
- [ ] Display on Profile Detail Screen
- [ ] Use for match prediction

**Files to Modify:**
- `lib/features/discover/services/discover_service.dart`

**Screens to Connect:**
- `lib/screens/profile/profile_detail_screen.dart`

---

#### Task 34: Get AI Match Suggestions API
- [ ] Endpoint: `GET /matching/ai-suggestions`
- [ ] Response: AI-powered match suggestions
- [ ] Use for premium feature or special section

**Files to Modify:**
- `lib/features/discover/services/discover_service.dart`

---

### ❤️ Phase 6: Likes & Superlikes

#### Task 35: Like User API
- [ ] Endpoint: `POST /likes/like`
- [ ] Request body: `{liked_user_id}`
- [ ] Response: `{status, message, is_match: bool}`
- [ ] If `is_match: true` → Show Match Screen
- [ ] Update UI optimistically

**Files to Create:**
- `lib/features/matching/services/like_service.dart`

**Screens to Connect:**
- `lib/pages/discovery_page.dart` (swipe right)

---

#### Task 36: Dislike User API
- [ ] Endpoint: `POST /likes/dislike`
- [ ] Request body: `{liked_user_id}`
- [ ] Remove from discovery stack
- [ ] Don't show again

**Files to Modify:**
- `lib/features/matching/services/like_service.dart`

**Screens to Connect:**
- `lib/pages/discovery_page.dart` (swipe left)

---

#### Task 37: Superlike User API
- [ ] Endpoint: `POST /likes/superlike`
- [ ] Request body: `{liked_user_id}`
- [ ] Check if user has superlike packs available
- [ ] Deduct from pack
- [ ] Show special animation

**Files to Modify:**
- `lib/features/matching/services/like_service.dart`

**Screens to Connect:**
- `lib/pages/discovery_page.dart` (swipe up)

---

#### Task 38: Get Matches API
- [ ] Endpoint: `GET /likes/matches`
- [ ] Response: List of mutual matches
- [ ] Display in Matches/Likes screen
- [ ] Show match date, last message preview

**Files to Modify:**
- `lib/features/matching/services/like_service.dart`

**Screens to Connect:**
- `lib/pages/home_page.dart` (Likes tab - if exists)

---

#### Task 39: Get Pending Likes API
- [ ] Endpoint: `GET /likes/pending`
- [ ] Response: List of users who liked current user
- [ ] Display in "Likes You" section
- [ ] Allow responding (like back or pass)

**Files to Modify:**
- `lib/features/matching/services/like_service.dart`

---

#### Task 40: Get Superlike History API
- [ ] Endpoint: `GET /likes/superlike-history`
- [ ] Response: History of sent/received superlikes
- [ ] Display in profile or settings

**Files to Modify:**
- `lib/features/matching/services/like_service.dart`

---

### 💬 Phase 7: Chat & Messaging

#### Task 41: Send Message API
- [ ] Endpoint: `POST /chat/send`
- [ ] Request body: `{receiver_id, message, message_type}`
- [ ] Message types: `text`, `image`, `video`, `voice`, `location`
- [ ] Optimistic UI update
- [ ] Handle send failures

**Files to Create:**
- `lib/features/chat/services/chat_service.dart`
- `lib/features/chat/models/message_model.dart`

**Screens to Connect:**
- `lib/pages/chat_page.dart`

---

#### Task 42: Get Chat History API
- [ ] Endpoint: `GET /chat/history`
- [ ] Query params: `?user_id={id}&page={page}&limit={limit}`
- [ ] Response: Paginated message list
- [ ] Implement infinite scroll
- [ ] Cache messages locally

**Files to Modify:**
- `lib/features/chat/services/chat_service.dart`

**Screens to Connect:**
- `lib/pages/chat_page.dart`

---

#### Task 43: Get Chat Users API
- [ ] Endpoint: `GET /chat/users`
- [ ] Response: List of users with conversations
- [ ] Include: last message, timestamp, unread count
- [ ] Sort by last message time

**Files to Modify:**
- `lib/features/chat/services/chat_service.dart`

**Screens to Connect:**
- `lib/pages/chat_list_page.dart`

---

#### Task 44: Delete Message API
- [ ] Endpoint: `DELETE /chat/message`
- [ ] Request body: `{message_id}`
- [ ] Update UI immediately
- [ ] Handle errors

**Files to Modify:**
- `lib/features/chat/services/chat_service.dart`

---

#### Task 45: Set Typing Status API
- [ ] Endpoint: `POST /chat/typing`
- [ ] Request body: `{receiver_id, is_typing}`
- [ ] Call when user starts/stops typing
- [ ] Debounce API calls (don't spam)

**Files to Modify:**
- `lib/features/chat/services/chat_service.dart`

**Screens to Connect:**
- `lib/pages/chat_page.dart` (typing indicator)

---

#### Task 46: Mark as Read API
- [ ] Endpoint: `POST /chat/read`
- [ ] Request body: `{receiver_id}`
- [ ] Call when chat is opened
- [ ] Update unread counts

**Files to Modify:**
- `lib/features/chat/services/chat_service.dart`

**Screens to Connect:**
- `lib/pages/chat_page.dart` (on open)

---

#### Task 47: WebSocket Setup for Real-time Chat
- [ ] Set up Socket.IO client connection
- [ ] Connect on app launch (if authenticated)
- [ ] Listen to events:
  - [ ] `message` - New message received
  - [ ] `typing` - User typing indicator
  - [ ] `online` - User online status
  - [ ] `read` - Message read receipt
- [ ] Emit events:
  - [ ] `send_message`
  - [ ] `typing_start/stop`
  - [ ] `mark_read`
- [ ] Handle reconnection
- [ ] Update UI in real-time

**Files to Modify:**
- `lib/shared/services/websocket_service.dart`

**Screens to Connect:**
- `lib/pages/chat_page.dart`
- `lib/pages/chat_list_page.dart`

---

### 🔔 Phase 8: Notifications

#### Tasks 48-52: Notification APIs
- [ ] **Task 48**: Get Notifications (`GET /notifications`) - Paginated list
- [ ] **Task 49**: Get Unread Count (`GET /notifications/unread-count`)
- [ ] **Task 50**: Mark as Read (`POST /notifications/{id}/read`)
- [ ] **Task 51**: Mark All as Read (`POST /notifications/read-all`)
- [ ] **Task 52**: Delete Notification (`DELETE /notifications/{id}`)

**Implementation Notes:**
- Poll for notifications every 30 seconds (or use WebSocket)
- Update badge count in bottom nav
- Show notification list in notifications screen
- Handle different notification types (match, message, like, etc.)

**Files to Create:**
- `lib/features/notifications/services/notification_service.dart`
- `lib/features/notifications/models/notification_model.dart`

**Screens to Connect:**
- Notification settings screen
- Home page (badge count)

---

### 📸 Phase 9: Stories & Feeds

#### Task 53: Get Stories API
- [ ] Endpoint: `GET /stories`
- [ ] Response: List of stories from matched users
- [ ] Display in story carousel
- [ ] Show viewed/unviewed state

**Files to Create:**
- `lib/features/stories/services/story_service.dart`
- `lib/features/stories/models/story_model.dart`

**Screens to Connect:**
- `lib/pages/discovery_page.dart` (top carousel)
- `lib/pages/feed_page.dart` (top carousel)

---

#### Task 54: Upload Story API
- [ ] Endpoint: `POST /stories/upload`
- [ ] Multipart form data: `{image: File, caption: String}`
- [ ] Compress image before upload
- [ ] Show upload progress

**Files to Modify:**
- `lib/features/stories/services/story_service.dart`

**Screens to Connect:**
- `lib/screens/stories/story_creation_screen.dart`

---

#### Task 55: Like Story API
- [ ] Endpoint: `POST /stories/{id}/like`
- [ ] Toggle like state
- [ ] Update UI immediately

**Files to Modify:**
- `lib/features/stories/services/story_service.dart`

---

#### Tasks 56-59: Feed APIs
- [ ] **Task 56**: Get Feeds (`GET /feeds`) - Paginated social feed
- [ ] **Task 57**: Create Feed (`POST /feeds/create`) - Multipart with image
- [ ] **Task 58**: React to Feed (`POST /feeds/{id}/reactions`) - Like, love, etc.
- [ ] **Task 59**: Add Comment (`POST /feeds/{id}/comments`)

**Files to Create:**
- `lib/features/feed/services/feed_service.dart`
- `lib/features/feed/models/feed_post_model.dart`

**Screens to Connect:**
- `lib/pages/feed_page.dart`

---

### 🛡️ Phase 10: User Actions

#### Tasks 60-65: User Action APIs
- [ ] **Task 60**: Block User (`POST /block/user`) - `{blocked_user_id, reason}`
- [ ] **Task 61**: Unblock User (`DELETE /block/user`)
- [ ] **Task 62**: Get Blocked Users (`GET /block/list`)
- [ ] **Task 63**: Report User (`POST /reports`) - `{reported_user_id, reason, description}`
- [ ] **Task 64**: Mute User (`POST /mutes/mute`)
- [ ] **Task 65**: Add to Favorites (`POST /favorites/add`)

**Files to Create:**
- `lib/features/safety/services/safety_service.dart`

**Screens to Connect:**
- Profile detail screen (block/report buttons)
- Settings screens (blocked users list)
- Chat page (mute option)

---

### 💳 Phase 11: Payments & Subscriptions

#### Tasks 66-71: Payment APIs
- [ ] **Task 66**: Get Plans (`GET /plans`) - Subscription plans
- [ ] **Task 67**: Get Sub Plans (`GET /sub-plans`) - Monthly/yearly options
- [ ] **Task 68**: Subscribe to Plan (`POST /subscriptions/subscribe`)
- [ ] **Task 69**: Get Subscription Status (`GET /subscriptions/status`)
- [ ] **Task 70**: Create Stripe Checkout (`POST /stripe/checkout`)
- [ ] **Task 71**: Cancel Subscription (`DELETE /stripe/subscription/{id}`)

**Implementation Notes:**
- Integrate `flutter_stripe` for payment processing
- Handle payment success/failure callbacks
- Update user premium status after successful payment
- Show subscription status in profile

**Files to Create:**
- `lib/features/payments/services/payment_service.dart`
- `lib/features/payments/services/stripe_service.dart`
- `lib/features/payments/models/subscription_plan_model.dart`

**Screens to Connect:**
- `lib/screens/subscription_plans_screen.dart`
- `lib/screens/payment_screen.dart`

---

### ⭐ Phase 12: Superlikes

#### Tasks 72-74: Superlike Pack APIs
- [ ] **Task 72**: Get Available Superlike Packs (`GET /superlike-packs/available`)
- [ ] **Task 73**: Purchase Superlike Pack (`POST /superlike-packs/purchase`)
- [ ] **Task 74**: Get User Superlike Packs (`GET /superlike-packs/user-packs`)

**Files to Create:**
- `lib/features/superlikes/services/superlike_service.dart`
- `lib/features/superlikes/models/superlike_pack_model.dart`

**Screens to Connect:**
- Superlike packs screen
- Discovery page (show available superlikes count)

---

### 🎨 Phase 13: UI Integration

#### Tasks 75-92: Connect Screens to APIs

**Authentication Flow:**
- [ ] **Task 75**: Connect WelcomeScreen → Register API
- [ ] **Task 76**: Connect LoginScreen → Login API + user state checks
- [ ] **Task 77**: Connect EmailVerificationScreen → Verify Email API
- [ ] **Task 78**: Connect ProfileWizardScreen → Complete Registration API

**Profile Management:**
- [ ] **Task 79**: Connect ProfileEditPage → Update Profile + Image Upload APIs
- [ ] **Task 86**: Connect ProfilePage → Get My Profile API

**Discovery:**
- [ ] **Task 80**: Connect DiscoveryPage → Nearby Suggestions API + swipe actions
- [ ] **Task 81**: Connect DiscoveryPage → Match detection after swipes

**Chat:**
- [ ] **Task 82**: Connect ChatListPage → Get Chat Users API
- [ ] **Task 83**: Connect ChatPage → Send Message + Get Chat History APIs
- [ ] **Task 84**: Connect ChatPage → WebSocket for real-time updates

**Feed:**
- [ ] **Task 85**: Connect FeedPage → Get Feeds + Stories APIs

**Onboarding:**
- [ ] **Task 87**: Connect OnboardingPreferencesScreen → Save preferences

**General:**
- [ ] **Task 88**: Implement token refresh mechanism
- [ ] **Task 89**: Implement offline support (cache + sync)
- [ ] **Task 90**: Implement error handling with user-friendly messages
- [ ] **Task 91**: Implement loading states and skeleton loaders
- [ ] **Task 92**: Implement retry mechanism for failed API calls

---

## 📊 Implementation Priority

### High Priority (Week 1)
1. Core Infrastructure (Tasks 1-5)
2. Authentication & Registration (Tasks 6-10)
3. Reference Data (Tasks 11-20)
4. Basic Profile Management (Tasks 24-26)

### Medium Priority (Week 2)
5. Discovery & Matching (Tasks 31-34)
6. Likes & Superlikes (Tasks 35-40)
7. Chat & Messaging (Tasks 41-47)
8. Image Management (Tasks 27-30)

### Lower Priority (Week 3+)
9. Notifications (Tasks 48-52)
10. Stories & Feeds (Tasks 53-59)
11. Payments & Subscriptions (Tasks 66-71)
12. User Actions (Tasks 60-65)
13. Superlikes (Tasks 72-74)

---

## 🔄 User Flow Mapping

### New User Registration Flow
1. WelcomeScreen → Task 6 (Register)
2. EmailVerificationScreen → Task 9 (Verify Email)
3. ProfileWizardScreen → Tasks 11-20 (Reference Data) + Task 10 (Complete Registration)
4. OnboardingPreferencesScreen → Task 87 (Save Preferences)
5. HomePage → Ready!

### Existing User Login Flow
1. SplashPage → Task 8 (Check User State)
2. LoginScreen → Task 7 (Login)
3. Based on state:
   - Email verification needed → Task 9
   - Profile incomplete → Task 10
   - Ready → HomePage

### Main App Usage Flow
1. DiscoveryPage → Tasks 31-32 (Get Suggestions) + Tasks 35-37 (Like/Dislike/Superlike)
2. ChatListPage → Task 43 (Get Chat Users)
3. ChatPage → Tasks 41-42, 46 (Send/Get Messages, Mark Read) + Task 47 (WebSocket)
4. FeedPage → Tasks 53, 56 (Stories & Feeds)
5. ProfilePage → Task 24 (Get My Profile)

---

## 📝 Notes

- All API calls should use Riverpod providers for state management
- Implement proper error handling with user-friendly messages
- Add loading states for all async operations
- Cache frequently accessed data (reference data, user profile)
- Implement retry logic for network failures
- Use optimistic UI updates where appropriate
- Handle token expiration and refresh automatically
- Test all API integrations thoroughly
- Monitor API response times and optimize

---

**Last Updated**: December 2024  
**Total Tasks**: 92  
**Status**: Planning Phase

