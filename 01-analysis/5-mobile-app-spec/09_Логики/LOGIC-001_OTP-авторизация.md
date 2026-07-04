# LOGIC-001 — OTP-авторизация

## Где используется

SCR-001.

## Правила

1. Пользователь вводит телефон.
2. Flutter-клиент вызывает `sendOtp`.
3. Пользователь вводит SMS-код.
4. Клиент вызывает `verifyOtp`.
5. Access/refresh токены сохраняются в защищённом хранилище.

## Ошибки

`invalid_code`, `rate_limit`, `server_error`, `unauthorized`.

## Flutter-заметки

Токены хранить через `flutter_secure_storage` или эквивалент, не в обычном shared preferences.
