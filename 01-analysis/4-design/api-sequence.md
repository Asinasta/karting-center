# Sequence-диаграммы API

> Этап 4. Критичные сценарии взаимодействия Flutter-клиента и API.

## Общие правила

- `GET /slots`, `GET /slots/{slotId}` и `GET /marshals` доступны без авторизации.
- Все персональные запросы и мутации используют `Authorization: Bearer <access_token>`.
- При `401` Flutter-клиент пытается обновить access token по refresh token.
- Создание брони всегда отправляется с `Idempotency-Key`.
- `createBooking` передаёт выбранные места массивом `seat_gear[]`; `seats_count` вычисляется сервером как длина массива.
- Сервер — источник истины по местам, прокатной экипировке, цене и времени.
- До создания брони клиент показывает локальный price preview; финальный `price_total` берётся только из ответа `createBooking`.

## Сценарий 1: Создание брони

```mermaid
sequenceDiagram
  actor User as Клиент
  participant App as Flutter App
  participant API as Bookings API

  User->>App: Нажимает «Записаться»
  alt Нет активной сессии
    App->>API: POST /auth/otp + POST /auth/verify
    API-->>App: TokenPair
  end
  App->>App: Генерирует Idempotency-Key
  App->>API: POST /bookings {slot_id, seat_gear[]} + Bearer + Idempotency-Key
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
  else Уже есть активная бронь
    API-->>App: 409 double_booking {booking_id}
    App-->>User: Предложить открыть существующую бронь
  else Слот уже стартовал
    API-->>App: 422 slot_started
    App-->>User: Запись недоступна
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

## Сценарий 4: Смена телефона в профиле

```mermaid
sequenceDiagram
  actor User as Клиент
  participant App as Flutter App
  participant API as Profile API

  User->>App: Вводит новый номер
  App->>API: POST /profile/phone-change/otp {new_phone} + Bearer
  alt OTP отправлен
    API-->>App: 204
    User->>App: Вводит SMS-код
    App->>API: POST /profile/phone-change/verify {new_phone, code} + Bearer
    API-->>App: 200 Profile {phone: new_phone}
  else Номер занят
    API-->>App: 409 phone_already_used
    App-->>User: Старый номер остаётся активным
  else Неверный код или rate limit
    API-->>App: invalid_code / rate_limit
    App-->>User: Показать ошибку, старый номер остаётся активным
  end
```
