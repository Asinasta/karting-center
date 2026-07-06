# Запуск в Docker (для проверки)

Проверяющему не нужны Python, Flutter и локальные venv — только Docker.

## Требования

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/macOS) или Docker Engine (Linux)
- Git

## Быстрый старт

```bash
git clone https://github.com/Asinasta/karting-center.git
cd karting-center
docker compose up --build
```

Первая сборка может занять **10–20 минут** (скачивается Flutter SDK и собирается web-клиент). Следующие запуски — быстрее.

## Куда открывать

| URL | Что это |
|-----|---------|
| http://localhost:3000 | Приложение (Flutter Web) |
| http://localhost:8080/docs | Swagger API |
| http://localhost:8080/healthz | Healthcheck backend |

## Тестовые данные (fixtures)

| Параметр | Значение |
|----------|----------|
| OTP-код | `0000` |
| Телефон с историей | `+79990000000` |
| Новый пользователь | любой `+7...` в формате E.164 |

## Остановка

```bash
docker compose down
```

## Только API (без UI)

```bash
docker compose up --build backend
```

## Устранение проблем

**Порт занят** — остановите локальный backend/Flutter или смените порты в `docker-compose.yml`.

**Сборка web падает по памяти** — в Docker Desktop увеличьте Memory до 4–8 GB.

**Приложение открывается, но API не отвечает** — дождитесь `healthy` у сервиса `backend` (`docker compose ps`).
