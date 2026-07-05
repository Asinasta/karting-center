import '../../../core/network/api_client.dart';
import '../domain/slot_filter.dart';
import '../domain/slot_models.dart';

abstract class SlotRepository {
  /// `listSlots`: GET /slots — public, no token.
  Future<List<Slot>> listSlots({SlotFilter filter = SlotFilter.defaults});

  /// `getSlot`: GET /slots/{slotId} — public, no token.
  Future<Slot> getSlot(String slotId);
}

class ApiSlotRepository implements SlotRepository {
  const ApiSlotRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Slot>> listSlots({SlotFilter filter = SlotFilter.defaults}) async {
    final payload = await _apiClient.get('/slots', query: filter.toQuery());
    final items = payload! as List<dynamic>;
    final slots = items
        .map((item) => Slot.fromJson(item as Map<String, Object?>))
        .toList();
    slots.sort((a, b) => a.startAt.compareTo(b.startAt));
    return slots;
  }

  @override
  Future<Slot> getSlot(String slotId) async {
    final payload = await _apiClient.get('/slots/$slotId');
    return Slot.fromJson(payload! as Map<String, Object?>);
  }
}
