# SCR-001 — Регистрация / вход

## API

- `sendOtp`: `POST /auth/otp`
- `verifyOtp`: `POST /auth/verify`
- `refreshToken`: `POST /auth/refresh`

## UI

Телефон, SMS-код, имя для нового пользователя, ссылки на согласие и политику.

## Состояния и ошибки

Loading, invalid_code, rate_limit, server_error.

## Применяемые логики

LOGIC-001, LOGIC-008.
