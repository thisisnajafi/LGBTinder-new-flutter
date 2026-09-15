import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/theme/app_colors.dart';
import 'package:lgbtindernew/features/payments/utils/purchase_status_style.dart';

void main() {
  test('completed maps to online green badge', () {
    final style = PurchaseStatusStyle.fromStatus('completed');
    expect(style.label, 'Completed');
    expect(style.badgeColor, AppColors.onlineGreen);
    expect(style.foregroundColor, AppColors.backgroundLight);
  });

  test('pending maps to warning badge', () {
    final style = PurchaseStatusStyle.fromStatus('PENDING');
    expect(style.label, 'Pending');
    expect(style.badgeColor, AppColors.feedbackWarning);
  });

  test('unknown status keeps original label', () {
    final style = PurchaseStatusStyle.fromStatus('chargeback');
    expect(style.label, 'chargeback');
    expect(style.badgeColor, AppColors.textTertiaryLight);
  });
}
