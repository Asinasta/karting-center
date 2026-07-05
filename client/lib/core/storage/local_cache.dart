/// In-memory read-only fallback cache (MVP decision for the open question in
/// CMP_CLIENT_IMPLEMENTATION_PLAN: memory/session cache, not persistent).
///
/// Used only to show `Offline stale` content when a reload fails.
class LocalCache<T> {
  T? _value;
  DateTime? _storedAt;

  T? get value => _value;
  DateTime? get storedAt => _storedAt;
  bool get hasValue => _value != null;

  void store(T value) {
    _value = value;
    _storedAt = DateTime.now();
  }

  void clear() {
    _value = null;
    _storedAt = null;
  }
}
