# TASK-02. Получить от ИИ архитектурный план и схему данных

## Цель

По требованиям MVP (TASK-01) получить с помощью ИИ архитектурный план клиентского API и Flutter-приложения, ресурсную модель данных и OpenAPI-контракт. Зафиксировать границы: клиент — только роль «Клиент», расписание и админка — во внешней инфраструктуре.

## Исходные требования

- Бриф: `01-analysis/0-customer-brief/customer-brief.md` (R-004, R-015, R-028).
- User stories / use cases: `01-analysis/2-requirements/user-stories.md`, `use-cases.md`.
- Планы разработки: `02-development/BE_IMPLEMENTATION_PLAN.md`, `02-development/CMP_CLIENT_IMPLEMENTATION_PLAN.md`.

## Что сделано

### Схема данных (ресурсная модель API, не БД)

`01-analysis/4-design/data-model.md`:

| Сущность | Назначение |
|---|---|
| `Client` | Профиль клиента (id, name, phone) |
| `TrackConfig` | Конфигурация трассы (novice / experienced, capacity_cap, geometry) |
| `Marshal` | Маршал-инструктор (read-only справочник) |
| `Slot` | Заезд: места, прокат, цена, точка сбора, статус |
| `Booking` | Бронь клиента с `BookingSlotSnapshot` |
| `Money`, `Pagination`, `Error` | Общие типы в `01-analysis/api/common/models.yaml` |

Каноническая схема — **контракт OpenAPI**, не SQL-схема (R-015).

### Архитектурный план

**Backend** (`backend/`, FastAPI):

```
HTTP handlers (routers)
    → domain policies (чистый Python)
    → ports.Backend
        → FixturesAdapter (dev/test, in-memory)
        → ExistingBackendAdapter (production, not implemented)
```

- Публичные endpoints без Bearer: `GET /slots`, `GET /slots/{id}`, `GET /marshals`.
- Защищённые: auth, bookings, profile.
- JWT access + refresh; OTP в fixtures с dev-кодом `0000`.
- Идемпотентность `createBooking` через заголовок `Idempotency-Key`.
- Локально **нет отдельной БД** — `FixturesAdapter` хранит состояние в памяти (`backend/app/adapters/fixtures.py`).

**Flutter client** (`client/`):

```
presentation (экраны SCR/BS)
    → data (репозитории, ApiClient)
    → domain (модели, policies)
```

- Навигация: go_router с auth gate и return intent.
- Сессия: `GuestSession` / `AuthenticatedSession`, токены только в secure storage.
- Сетевой слой: `401` → один refresh → повтор запроса.

Диаграмма потоков: `01-analysis/4-design/api-sequence.md`.

### OpenAPI

`01-analysis/api/` — auth, slots, bookings, profile, marshals; проверка: `manage.py contract-check`.

## Промпты

- `docs/prompts/chat-01-requirements-generation.txt` — data model и mobile spec.
- `docs/prompts/chat-02-requirements-audit-and-dev-plans.txt` — планы BE/Client.
- `docs/prompts/chat-04-backend-development.txt` — реализация FastAPI.
- `docs/prompts/chat-06-flutter-client-development.txt` — реализация Flutter.

## Проверка вручную

```powershell
cd backend
.\.venv\Scripts\python.exe manage.py contract-check
.\.venv\Scripts\python.exe manage.py test
```

- `contract-check` — 0 расхождений с OpenAPI.
- `test` — все pytest-тесты зелёные.
- `GET http://localhost:8080/slots` — JSON-массив слотов без токена.

## Коммиты

- `docs: add architecture and data model (task-02)` — этот документ.
- `feat(backend): FastAPI client API with fixtures adapter` — код `backend/`.
- `feat(client): Flutter MVP per CMP plan` — код `client/`.
