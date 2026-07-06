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
- `prompts/` — все промпты, отправленные ИИ, выгруженные из чатов Cursor (по одному файлу на чат, в хронологическом порядке).

## Задачи

| # | Документ | Суть |
|---|---|---|
| 1 | [TASK-01-requirements.md](tasks/TASK-01-requirements.md) | Требования к MVP: user stories + сценарии |
| 2 | [TASK-02-architecture.md](tasks/TASK-02-architecture.md) | Архитектурный план и схема данных |
| 3 | [TASK-03-features.md](tasks/TASK-03-features.md) | Реализованные фичи (3+) |
| 4 | [TASK-04-test-cases.md](tasks/TASK-04-test-cases.md) | Тест-кейсы и автотесты |

## Баги

| # | Документ | Симптом |
|---|---|---|
| 1 | [BUG-001-slot-filters-ignored.md](bugs/BUG-001-slot-filters-ignored.md) | Клиент игнорировал фильтры при запросе `GET /slots` |
| 2 | [BUG-002-money-kopecks-lost.md](bugs/BUG-002-money-kopecks-lost.md) | Цена теряла копейки при форматировании |
| 3 | [BUG-003-no-session-check-and-auth-gate.md](bugs/BUG-003-no-session-check-and-auth-gate.md) | Splash не проверял сессию, защищённые разделы без auth gate |
