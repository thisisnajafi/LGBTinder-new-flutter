/// CODE QUALITY (Task 8.2.3): Widget Decomposition Guide
///
/// This guide explains how to decompose large screens into smaller, reusable widgets.
///
/// ## When to Decompose
///
/// - Screen build method > 200 lines
/// - Repeated UI patterns in multiple screens
/// - Complex state logic mixed with UI
/// - Nested callbacks deeper than 3 levels
///
/// ## Decomposition Strategy
///
/// ### 1. Identify Logical Sections
///
/// Look for natural groupings in your UI:
/// - Headers / App Bars
/// - Content sections
/// - Lists / Grids
/// - Action buttons / FABs
/// - Dialogs / Bottom sheets
///
/// ### 2. Extract Private Widgets First
///
/// Start with private widgets within the same file:
///
/// ```dart
/// // Before
/// class MyScreen extends StatelessWidget {
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         // 100 lines of header code...
///         // 200 lines of content code...
///       ],
///     );
///   }
/// }
///
/// // After
/// class MyScreen extends StatelessWidget {
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         _Header(),
///         _Content(),
///       ],
///     );
///   }
/// }
///
/// class _Header extends StatelessWidget {
///   // Header widget implementation
/// }
///
/// class _Content extends StatelessWidget {
///   // Content widget implementation
/// }
/// ```
///
/// ### 3. Move Reusable Widgets to Separate Files
///
/// When a widget is used in multiple screens:
///
/// ```
/// lib/features/{feature}/presentation/
/// ├── screens/
/// │   └── my_screen.dart
/// └── widgets/
///     ├── header_widget.dart
///     ├── content_section.dart
///     └── action_buttons.dart
/// ```
///
/// ### 4. Use Composition Over Inheritance
///
/// Prefer composing widgets over extending them:
///
/// ```dart
/// // Good - Composition
/// class PlanCard extends StatelessWidget {
///   final Plan plan;
///   final VoidCallback onTap;
///   
///   Widget build(BuildContext context) {
///     return Card(
///       child: PlanCardContent(plan: plan),
///       onTap: onTap,
///     );
///   }
/// }
///
/// // Avoid - Inheritance
/// class PlanCard extends Card {
///   // Don't extend Flutter widgets
/// }
/// ```
///
/// ## Example: Subscription Plans Screen Decomposition
///
/// Original structure (597 lines):
/// ```dart
/// class SubscriptionPlansScreen extends StatelessWidget {
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(...), // 30 lines
///       body: Column(
///         children: [
///           // Header section - 50 lines
///           // Plan cards section - 300 lines
///           // Features comparison - 150 lines
///           // CTA buttons - 50 lines
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// Decomposed structure:
/// ```dart
/// class SubscriptionPlansScreen extends StatelessWidget {
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: const SubscriptionAppBar(),
///       body: Column(
///         children: [
///           const SubscriptionHeader(),
///           Expanded(
///             child: PlanCardsList(
///               onPlanSelected: (plan) => _handlePlanSelected(plan),
///             ),
///           ),
///           const FeatureComparisonSection(),
///           SubscriptionCTAButtons(
///             onSubscribe: () => _handleSubscribe(),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// ## File Structure After Decomposition
///
/// ```
/// lib/features/payments/presentation/
/// ├── screens/
/// │   └── subscription_plans_screen.dart (100 lines)
/// └── widgets/
///     ├── subscription_app_bar.dart
///     ├── subscription_header.dart
///     ├── plan_cards_list.dart
///     ├── plan_card.dart
///     ├── feature_comparison_section.dart
///     ├── feature_row.dart
///     └── subscription_cta_buttons.dart
/// ```
///
/// ## Performance Considerations
///
/// 1. **Use const constructors** when possible:
///    ```dart
///    const MyWidget({super.key});
///    ```
///
/// 2. **Avoid unnecessary rebuilds** by extracting stateless parts:
///    ```dart
///    // The const header won't rebuild when parent changes
///    const SubscriptionHeader(),
///    ```
///
/// 3. **Pass only necessary data** to child widgets:
///    ```dart
///    // Good - Only pass what's needed
///    PlanCard(title: plan.title, price: plan.price)
///    
///    // Avoid - Passing entire objects when not needed
///    PlanCard(plan: entirePlanObject)
///    ```
///
/// 4. **Use Builder widgets** for scoped rebuilds:
///    ```dart
///    Consumer(
///      builder: (context, ref, child) {
///        // Only this section rebuilds
///      },
///    )
///    ```

library widget_decomposition_guide;

/// Example of a well-decomposed screen structure
abstract class WellDecomposedScreen {
  /// Main screen widget - should be < 100 lines
  /// Only orchestrates child widgets, no complex UI logic
  void mainScreen() {}

  /// Header section - reusable across screens
  void headerSection() {}

  /// Content section - can be scrollable
  void contentSection() {}

  /// Action section - buttons, FABs, etc.
  void actionSection() {}
}

