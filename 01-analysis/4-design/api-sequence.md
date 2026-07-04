# Sequence-диаграммы API

> Этап 4. Критичные сценарии взаимодействия Flutter-клиента и API.

## Общие правила

- Все защищённые запросы используют `Authorization: Bearer <access_token>`.
- При `401` Flutter-клиент пытается обновить access token по refresh token.
- Создание брони всегда отправляется с `Idempotency-Key`.
- Сервер — источник истины по местам, прокатной экипировке, цене и времени.

## Сценарий 1: Создание брони

```mermaid
sequenceDiagram
  actor User as Клиент
  participant App as Flutter App
  participant API as Bookings API

  User->>App: Нажимает «Записаться»
  App->>App: Генерирует Idempotency-Key
  App->>API: POST /bookings {slot_id, seats_count, seat_gear[]} + Bearer + Idempotency-Key
  API->>API: Проверяет места, прокатную экипировку, статус слота
  alt Успех
    API-->>App: 201 Booking {status: active, price_total}
    App-->>User: Экран успеха
  else Нет мест или экипировки
    API-->>App: 409 slot_full
    App-->>User: Показать актуальную доступность
  else Слот отменён
    API-->>App: 410 slot_cancelled
    App-->>User: Отключить CTA записи
  else Таймаут
    App->>API: Повтор с тем же Idempotency-Key
    API-->>App: Тот же результат без дубля
  end
```

## Сценарий 2: Отмена брони

```mermaid
sequenceDiagram
  actor User as Клиент
  participant App as Flutter App
  participant API as Bookings API

  User->>App: Подтверждает отмену
  App->>API: POST /bookings/{bookingId}/cancel + Bearer
  API->>API: Определяет время до старта по серверному времени
  alt Ранняя отмена
    API-->>App: 200 Booking {status: cancelled}
    App-->>User: «Запись отменена, места освобождены»
  else Поздняя отмена
    API-->>App: 200 Booking {status: late_cancel}
    App-->>User: «Поздняя отмена, место не освобождено»
  else Заезд уже стартовал
    API-->>App: 422 slot_started
    App-->>User: Отмена недоступна
  else Бронь уже отменена
    API-->>App: 409 already_cancelled
    App-->>User: Показать текущий статус
  end
```

## Сценарий 3: Обновление access token

```mermaid
sequenceDiagram
  participant App as Flutter App
  participant API as API

  App->>API: Любой защищённый запрос
  API-->>App: 401 unauthorized
  App->>API: POST /auth/refresh {refresh_token}
  alt Успех
    API-->>App: TokenPair
    App->>API: Повтор исходного запроса
  else Refresh истёк
    API-->>App: 401 unauthorized
    App-->>App: Очистить secure storage
  end
```
