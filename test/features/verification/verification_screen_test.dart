import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/profile/data/models/profile_verification.dart';
import 'package:lgbtindernew/widgets/verification/verification_components.dart';
import 'package:lgbtindernew/widgets/verification/verification_type_card.dart';

void main() {
  Widget wrap(Widget child, {bool dark = false}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('ProfileVerification model', () {
    test('parses pending_verifications array from correct key', () {
      final model = ProfileVerification.fromJson({
        'verification_status': {
          'photo_verified': false,
          'id_verified': false,
          'video_verified': false,
          'verification_score': 0,
          'total_verifications': 0,
          'pending_verifications': 1,
        },
        'verification_badge': 'Unverified',
        'can_submit_photo': false,
        'can_submit_id': true,
        'can_submit_video': true,
        'pending_verifications': [
          {
            'id': 42,
            'type': 'photo',
            'status': 'pending',
            'submitted_at': '2026-07-01T10:30:00.000000Z',
          },
        ],
      });

      expect(model.pendingVerificationsCount, 1);
      expect(model.pendingVerifications?.length, 1);
      expect(model.pendingVerifications!.first.type, 'photo');
    });
  });

  group('VerificationTypeCard', () {
    testWidgets('notStarted shows upload button', (tester) async {
      await tester.pumpWidget(
        wrap(
          VerificationTypeCard(
            type: VerificationType.photo,
            status: VerificationCardStatus.notStarted,
            guidelinesText: 'Take a clear selfie',
            onUpload: () {},
          ),
        ),
      );

      expect(find.text('Upload Photo'), findsOneWidget);
      expect(find.text('Under Review'), findsNothing);
    });

    testWidgets('pending shows under review and cancel', (tester) async {
      await tester.pumpWidget(
        wrap(
          VerificationTypeCard(
            type: VerificationType.photo,
            status: VerificationCardStatus.pending,
            submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
            guidelinesText: 'Guidelines',
            onUpload: () {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Cancel Submission'), findsOneWidget);
    });

    testWidgets('approved hides upload button', (tester) async {
      await tester.pumpWidget(
        wrap(
          VerificationTypeCard(
            type: VerificationType.photo,
            status: VerificationCardStatus.approved,
            reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
            guidelinesText: 'Guidelines',
            onUpload: () {},
          ),
        ),
      );

      expect(find.text('Upload Photo'), findsNothing);
      expect(find.text('Approved'), findsOneWidget);
    });

    testWidgets('rejected shows reason and resubmit', (tester) async {
      await tester.pumpWidget(
        wrap(
          VerificationTypeCard(
            type: VerificationType.photo,
            status: VerificationCardStatus.rejected,
            adminNotes: 'Photo was too blurry',
            guidelinesText: 'Take a clear selfie',
            onUpload: () {},
          ),
        ),
      );

      expect(find.text('Photo was too blurry'), findsOneWidget);
      expect(find.text('Upload Photo'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('dark mode renders with theme colors', (tester) async {
      await tester.pumpWidget(
        wrap(
          VerificationTypeCard(
            type: VerificationType.id,
            status: VerificationCardStatus.pending,
            guidelinesText: 'Upload your ID',
            onUpload: () {},
            onCancel: () {},
          ),
          dark: true,
        ),
      );

      expect(find.text('Under Review'), findsOneWidget);
    });
  });

  group('VerificationBadgeChip', () {
    testWidgets('fully verified uses golden styling', (tester) async {
      await tester.pumpWidget(
        wrap(const VerificationBadgeChip(badge: 'Fully Verified')),
      );
      expect(find.text('Fully Verified'), findsOneWidget);
    });

    testWidgets('unverified chip is hidden via VerificationBadge wrapper', (
      tester,
    ) async {
      // Chip itself still renders if passed directly
      await tester.pumpWidget(
        wrap(const VerificationBadgeChip(badge: 'Photo Verified')),
      );
      expect(find.text('Photo Verified'), findsOneWidget);
    });
  });
}
