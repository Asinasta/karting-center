# Karting Center «Апекс»

Клиентское кроссплатформенное Flutter-приложение для записи на заезды в картинг-центре «Апекс».

## Структура репозитория

| Папка | Содержимое |
|---|---|
| [`01-analysis/`](01-analysis/) | Аналитика: бриф, требования, OpenAPI, ТЗ на Flutter-клиент |
| [`02-development/`](02-development/) | Планы реализации backend и Flutter-клиента |
| [`backend/`](backend/) | FastAPI client API (fixtures adapter для dev/test) |
| [`client/`](client/) | Flutter MVP-клиент |
| [`docs/`](docs/) | Документация поставки: задачи, баги, промпты |

## Быстрый старт

См. [`RUN_LOCAL.md`](RUN_LOCAL.md).

- Backend: `http://localhost:8080` (`/docs`, `/healthz`)
- Flutter web: `http://127.0.0.1:3000`
- Dev fixtures: телефон `+79990000000`, OTP `0000` (для любого номера в dev тоже `0000`)

## Скоуп MVP

Клиентская роль: просмотр слотов, OTP-вход, бронирование, мои записи, отмена, профиль, карта трассы, **оценка маршала**, **программа лояльности**, инфраструктура push.

Вне скоупа: админка, интерфейс маршала/владельца, CRUD расписания, онлайн-оплата, авто-погода.

Источник скоупа: [`01-analysis/0-customer-brief/customer-brief.md`](01-analysis/0-customer-brief/customer-brief.md). Канон для разработки — [`01-analysis/5-mobile-app-spec/`](01-analysis/5-mobile-app-spec/).
