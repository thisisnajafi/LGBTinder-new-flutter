// Screen: PrivacyPolicyScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_settings_detail.dart';
import 'legal_document_view.dart';

const _privacySections = [
  LegalDocumentSection(
    title: '1. Information We Collect',
    body:
        'We collect information you provide directly to us, such as when you create an account, complete your profile, use our services, or contact us for support.',
  ),
  LegalDocumentSection(
    title: '2. How We Use Your Information',
    body:
        'We use the information we collect to provide, maintain, and improve our services, process transactions, send you communications, and protect our users.',
  ),
  LegalDocumentSection(
    title: '3. Information Sharing',
    body:
        'We do not sell your personal information. We may share your information only in limited circumstances, such as with your consent, to comply with legal obligations, or to protect our users.',
  ),
  LegalDocumentSection(
    title: '4. Data Security',
    body:
        'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
  ),
  LegalDocumentSection(
    title: '5. Your Rights',
    body:
        'You have the right to access and update your personal information. '
        'To request account removal, contact our support team. '
        'You can also opt out of certain communications and data processing activities.',
  ),
  LegalDocumentSection(
    title: '6. Contact Us',
    body:
        'If you have questions about this Privacy Policy, please contact us at privacy@lgbtfinder.com.',
  ),
];

/// Privacy policy screen - Display privacy policy
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppSettingsDetailScaffold(
      title: 'Privacy policy',
      body: LegalDocumentView(
        lastUpdated: 'December 2024',
        sections: _privacySections,
      ),
    );
  }
}
