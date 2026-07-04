# SCR-001 — Регистрация / вход

## API

- `sendOtp`: `POST /auth/otp`
- `verifyOtp`: `POST /auth/verify`
- `refreshToken`: `POST /auth/refresh`

## UI

Телефон, SMS-код, имя для нового пользователя, ссылки на согласие и политику.

Если вход запущен из сценария записи на заезд, после успешного OTP приложение возвращает пользователя к выбранному слоту или форме оформления.

## Состояния и ошибки

Loading, invalid_code, rate_limit с `retry_after`, code_expired, server_error.

## Применяемые логики

LOGIC-001, LOGIC-008.
