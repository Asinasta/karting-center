import 'package:apex_client/features/slots/domain/slot_models.dart';
import 'package:apex_client/features/slots/presentation/slot_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final slot = Slot(
    id: '1',
    trackConfig: const TrackConfig(
      id: 'tc-1',
      name: 'Очень длинное название трассы для проверки переноса',
      type: TrackConfigType.experienced,
      capacityCap: 10,
    ),
    marshal: const Marshal(
      id: 'm-1',
      name: 'Александр Константинопольский',
      averageRating: 4.8,
      ratingCount: 127,
    ),
    startAt: DateTime(2026, 7, 7, 18, 30),
    totalSeats: 10,
    freeSeats: 3,
    freeRentalGear: 2,
    price: const Money(amount: 250000, currency: 'RUB'),
    rentalPrice: const Money(amount: 50000, currency: 'RUB'),
    meetingPoint: 'Пит-лейн',
    status: SlotStatus.scheduled,
  );

  testWidgets('SlotCard does not overflow on small viewport and large text',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: ListView(
              children: [
                SizedBox(
                  width: 320,
                  child: SlotCard(slot: slot, onBook: () {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
