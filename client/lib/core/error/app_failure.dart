/// Error codes from `01-analysis/api/common/models.yaml` (`Error.code` enum).
abstract final class ApiErrorCode {
  static const slotFull = 'slot_full';
  static const doubleBooking = 'double_booking';
  static const slotCancelled = 'slot_cancelled';
  static const slotStarted = 'slot_started';
  static const alreadyCancelled = 'already_cancelled';
  static const invalidCode = 'invalid_code';
  static const rateLimit = 'rate_limit';
  static const phoneAlreadyUsed = 'phone_already_used';
  static const unauthorized = 'unauthorized';
  static const forbidden = 'forbidden';
  static const notFound = 'not_found';
  static const validationError = 'validation_error';
  static const serverError = 'server_error';
}

/// Typed API/network failure. `code` keeps the raw API `Error.code`.
class AppFailure {
  const AppFailure({
    required this.message,
    this.code,
    this.details,
    this.retryAfter,
    this.isNetwork = false,
  });

  factory AppFailure.network(Object error) {
    return AppFailure(
      message: 'Не удалось подключиться к серверу',
      isNetwork: true,
      details: {'error': error.toString()},
    );
  }

  factory AppFailure.api(Map<String, Object?> body) {
    return AppFailure(
      code: body['code'] as String?,
      message: body['message'] as String? ?? 'Ошибка API',
      details: body['details'] as Map<String, Object?>?,
      retryAfter: body['retry_after'] as int?,
    );
  }

  final String message;
  final String? code;
  final Map<String, Object?>? details;
  final int? retryAfter;
  final bool isNetwork;

  bool get isUnauthorized => code == ApiErrorCode.unauthorized;

  /// `double_booking.details.booking_id` — used to open the existing booking.
  String? get existingBookingId {
    if (code != ApiErrorCode.doubleBooking) {
      return null;
    }
    return details?['booking_id'] as String?;
  }

  /// Server-side availability from `slot_full.details`.
  int? get detailsFreeSeats => details?['free_seats'] as int?;
  int? get detailsFreeRentalGear => details?['free_rental_gear'] as int?;

  String get uiMessage {
    return switch (code) {
      ApiErrorCode.slotFull => 'Свободных мест уже не хватает',
      ApiErrorCode.doubleBooking => 'У вас уже есть запись на этот заезд',
      ApiErrorCode.slotCancelled => 'Заезд отменён центром',
      ApiErrorCode.slotStarted => 'Заезд уже начался',
      ApiErrorCode.alreadyCancelled => 'Бронь уже отменена',
      ApiErrorCode.invalidCode => 'Неверный код из SMS',
      ApiErrorCode.rateLimit => retryAfter != null
          ? 'Слишком много попыток. Повторите через $retryAfter сек.'
          : 'Слишком много попыток. Попробуйте позже.',
      ApiErrorCode.phoneAlreadyUsed => 'Этот номер уже используется',
      ApiErrorCode.unauthorized => 'Требуется вход',
      ApiErrorCode.forbidden => 'Нет доступа',
      ApiErrorCode.notFound => 'Не найдено',
      ApiErrorCode.validationError => message,
      ApiErrorCode.serverError => 'Ошибка сервера. Попробуйте позже.',
      _ => message,
    };
  }
}

class AppFailureException implements Exception {
  const AppFailureException(this.failure);

  final AppFailure failure;

  @override
  String toString() {
    final details = failure.details;
    return details == null
        ? failure.message
        : '${failure.message} ($details)';
  }
}

/// Normalizes any thrown object into [AppFailure].
AppFailure toAppFailure(Object error) {
  if (error is AppFailureException) {
    return error.failure;
  }
  if (error is AppFailure) {
    return error;
  }
  return AppFailure.network(error);
}
