// Screen: TermsOfServiceScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_settings_detail.dart';
import 'legal_document_view.dart';

const _termsSections = [
  LegalDocumentSection(
    title: '1. Acceptance of Terms',
    body:
        'By accessing and using LGBTFinder, you accept and agree to be bound by the terms and provision of this agreement.',
  ),
  LegalDocumentSection(
    title: '2. User Accounts',
    body:
        'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
  ),
  LegalDocumentSection(
    title: '3. User Conduct',
    body:
        'You agree not to use the service to: harass, abuse, or harm other users; post false or misleading information; violate any applicable laws or regulations.',
  ),
  LegalDocumentSection(
    title: '4. Privacy',
    body:
        'Your use of LGBTFinder is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices.',
  ),
  LegalDocumentSection(
    title: '5. Premium Features',
    body:
        'Premium features are available through subscription. Subscriptions will automatically renew unless cancelled. You can cancel your subscription at any time.',
  ),
  LegalDocumentSection(
    title: '6. Termination',
    body:
        'We reserve the right to terminate or suspend your account and access to the service immediately, without prior notice, for conduct that we believe violates these Terms of Service.',
  ),
  LegalDocumentSection(
    title: '7. Contact Information',
    body:
        'If you have any questions about these Terms of Service, please contact us at legal@lgbtfinder.com.',
  ),
];

/// Terms of service screen - Display terms of service
class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppSettingsDetailScaffold(
      title: 'Terms of service',
      body: LegalDocumentView(
        lastUpdated: 'December 2024',
        sections: _termsSections,
      ),
    );
  }
}
