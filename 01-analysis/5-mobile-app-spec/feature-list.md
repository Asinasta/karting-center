# Фича-лист Flutter-приложения «Апекс»

## Назначение

Клиентское приложение для самостоятельной записи на заезды картинг-центра. Скоуп — только роль Клиент.

## Карта навигации

```mermaid
flowchart TD
  Start([Запуск]) --> Auth{Есть refresh token?}
  Auth -->|Нет| SCR001[SCR-001 Вход]
  Auth -->|Да| SCR002[SCR-002 Заезды]
  SCR001 --> SCR002
  SCR002 --> BS001[BS-001 Фильтры]
  SCR002 --> SCR003[SCR-003 Карточка]
  SCR003 --> SCR004[SCR-004 Оформление]
  SCR004 --> BS002[BS-002 Успех]
  SCR002 --> SCR005[SCR-005 Мои записи]
  SCR005 --> SCR006[SCR-006 Детали]
  SCR006 --> BS003[BS-003 Отмена]
  SCR003 --> BS004[BS-004 Карта]
  SCR002 --> SCR007[SCR-007 Профиль]
```

## Фичи

| ID | Фича | Приоритет | API |
| :-- | :-- | :-- | :-- |
| F-001 | OTP-вход | Must | `sendOtp`, `verifyOtp` |
| F-002 | Список заездов | Must | `listSlots` |
| F-003 | Фильтры | Must | `listSlots`, `listMarshals` |
| F-004 | Карточка заезда | Must | `getSlot` |
| F-005 | Создание брони | Must | `createBooking` |
| F-006 | Мои записи | Must | `listBookings` |
| F-007 | Отмена брони | Must | `cancelBooking` |
| F-008 | Профиль | Must | `getProfile`, `updateProfile`, `deleteAccount` |
| F-009 | Push | Should | `registerPushToken` |
| F-010 | Карта трассы | Must | данные `geometry`, `meeting_point` |
