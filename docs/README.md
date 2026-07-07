# Документация поставки MVP

Оформление работы по брифу `01-analysis/0-customer-brief/customer-brief.md`.

## См. также

- [`../README.md`](../README.md) — обзор репозитория
- [`../RUN_LOCAL.md`](../RUN_LOCAL.md) — локальный запуск
- [`../backend/README.md`](../backend/README.md) — API backend
- [`../client/README.md`](../client/README.md) — Flutter-клиент
- [`implementation-report.md`](implementation-report.md) — отчёт о реализации клиента

## Структура

- `tasks/` — документы по четырём основным задачам: цель, требования, реализация, проверка, коммиты.
- `bugs/` — найденные и исправленные баги: симптом, причина, исправление, проверка.
- [`prompts/prompts.md`](prompts/prompts.md) — отобранные и очищенные промпты.
- `screenshots/` — скриншоты UI MVP.

## Задачи

| # | Документ | Суть |
|---|---|---|
| 1 | [TASK-01-requirements.md](tasks/TASK-01-requirements.md) | Требования к MVP: user stories + сценарии |
| 2 | [TASK-02-architecture.md](tasks/TASK-02-architecture.md) | Архитектурный план и схема данных |
| 3 | [TASK-03-features.md](tasks/TASK-03-features.md) | Реализованные фичи |
| 4 | [TASK-04-test-cases.md](tasks/TASK-04-test-cases.md) | Тест-кейсы и автотесты |

## Баги

| # | Документ | Симптом |
|---|---|---|
| 1 | [BUG-001-past-booking-shows-active-status.md](bugs/BUG-001-past-booking-shows-active-status.md) | В «Прошедших» бронь показывала статус «Активна» |
| 2 | [BUG-002-loyalty-card-overflow.md](bugs/BUG-002-loyalty-card-overflow.md) | Карточка лояльности переполняла экран при крупном шрифте |
| 3 | [BUG-003-slot-card-chip-overflow.md](bugs/BUG-003-slot-card-chip-overflow.md) | Чипы в карточке заезда переполняли строку на узком экране |
| 4 | [BUG-004-session-check-during-build.md](bugs/BUG-004-session-check-during-build.md) | Проверка сессии на splash вызывала `setState during build` |
