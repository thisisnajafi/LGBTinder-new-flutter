/// CODE QUALITY (Task 8.2.1): Flutter Architecture Guide
///
/// This file documents the Clean Architecture pattern used in this codebase.
/// 
/// ## Layer Structure
/// 
/// ```
/// ┌─────────────────────────────────────────────────────────────┐
/// │                    PRESENTATION LAYER                       │
/// │  Widgets (UI) ←→ Providers (State) ←→ Use Cases (Logic)    │
/// └─────────────────────────────────────────────────────────────┘
///                              ↓
/// ┌─────────────────────────────────────────────────────────────┐
/// │                      DOMAIN LAYER                           │
/// │        Use Cases  ←→  Repositories (Abstract)               │
/// └─────────────────────────────────────────────────────────────┘
///                              ↓
/// ┌─────────────────────────────────────────────────────────────┐
/// │                       DATA LAYER                            │
/// │  Repositories (Impl) ←→ Services (API) ←→ Models (DTO)     │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Directory Structure per Feature
///
/// ```
/// lib/features/{feature_name}/
/// ├── data/
/// │   ├── models/           # Data models (DTOs)
/// │   ├── repositories/     # Repository implementations
/// │   └── services/         # API services
/// ├── domain/
/// │   ├── entities/         # Business entities (optional)
/// │   ├── repositories/     # Repository interfaces (optional)
/// │   └── use_cases/        # Business logic use cases
/// ├── presentation/
/// │   ├── screens/          # Full page widgets
/// │   ├── widgets/          # Reusable widgets
/// │   └── controllers/      # Screen-specific logic (optional)
/// └── providers/
///     └── {feature}_providers.dart  # Riverpod providers
/// ```
///
/// ## Provider Pattern
///
/// Providers should follow this hierarchy:
///
/// 1. **Service Providers**: Provide API services
///    ```dart
///    final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
///    ```
///
/// 2. **Repository Providers**: Depend on services
///    ```dart
///    final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
///      final apiService = ref.watch(apiServiceProvider);
///      return DiscoveryRepository(apiService);
///    });
///    ```
///
/// 3. **Use Case Providers**: Depend on repositories
///    ```dart
///    final getProfilesUseCaseProvider = Provider<GetProfilesUseCase>((ref) {
///      final repository = ref.watch(discoveryRepositoryProvider);
///      return GetProfilesUseCase(repository);
///    });
///    ```
///
/// 4. **State Providers**: Depend on use cases
///    ```dart
///    final discoveryProvider = StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
///      final getProfiles = ref.watch(getProfilesUseCaseProvider);
///      return DiscoveryNotifier(getProfilesUseCase: getProfiles);
///    });
///    ```
///
/// ## Best Practices
///
/// 1. **Use Cases**: One use case per action (SRP)
/// 2. **Repositories**: Abstract data source from business logic
/// 3. **Services**: Handle raw API calls and response parsing
/// 4. **Providers**: Never call API services directly from StateNotifier
/// 5. **Models**: Use fromJson/toJson for serialization
///
/// ## DO's
/// - ✅ Inject dependencies through constructor
/// - ✅ Use interfaces for repository abstractions
/// - ✅ Handle errors at appropriate levels
/// - ✅ Cache API responses where appropriate
/// - ✅ Use typed models instead of dynamic/Map
///
/// ## DON'Ts
/// - ❌ Call API services directly from UI widgets
/// - ❌ Store mutable state in static variables
/// - ❌ Use synchronous operations for I/O
/// - ❌ Throw raw exceptions from use cases (use Result types)
/// - ❌ Put business logic in widgets

library architecture_guide;

