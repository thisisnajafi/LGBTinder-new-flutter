import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/profile/utils/profile_customization_draft.dart';
import 'package:lgbtindernew/features/profile/utils/profile_qr.dart';
import 'package:lgbtindernew/features/profile/utils/profile_template_catalog.dart';
import 'package:lgbtindernew/screens/profile/profile_export_screen.dart';

void main() {
  setUp(ProfileTemplateCatalog.resetForTest);

  test('template catalog caches the same unmodifiable list', () {
    final first = ProfileTemplateCatalog.cached();
    final second = ProfileTemplateCatalog.cached();
    expect(identical(first, second), isTrue);
    expect(first.length, ProfileTemplateCatalog.defaults.length);
  });

  test('QR encode runs without dart:ui and produces a square matrix', () {
    final qr = encodeProfileQrSync('https://lgbtfinder.com/profile/12345');
    expect(qr.moduleCount, greaterThan(0));
    expect(qr.modules.length, qr.moduleCount * qr.moduleCount);
    expect(qr.modules.contains(1), isTrue);
  });

  test('customization draft notifies once per discrete change', () {
    final draft = ProfileCustomizationDraft();
    var count = 0;
    draft.addListener(() => count++);
    draft.setLayout('compact');
    draft.setLayout('compact');
    draft.setShowBadges(false);
    expect(draft.layout, 'compact');
    expect(draft.showBadges, isFalse);
    expect(count, 2);
    draft.dispose();
  });

  test('export progress stream emits 0–1 ticks', () async {
    final values = await profileExportProgressStream().toList();
    expect(values.first, closeTo(0.1, 0.001));
    expect(values.last, 1);
    expect(values, hasLength(10));
  });
}
