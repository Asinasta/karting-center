import 'package:apex_client/features/profile/domain/profile_models.dart';
import 'package:apex_client/features/profile/presentation/loyalty_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = Profile(
    id: '1',
    name: 'Тест',
    phone: '+79990000000',
    completedRidesCount: 8,
    loyaltyTier: LoyaltyTier.regular,
    loyaltyDiscountPercent: 10,
  );

  testWidgets('LoyaltyCard does not overflow on small viewport and large text',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: LoyaltyCard(profile: profile),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
