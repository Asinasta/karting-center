# ТЗ на мобильное приложение «Апекс»

> Этап 5. Детальное техническое задание на клиентское мобильное приложение картинг-центра.

## Технология

Приложение реализуется на **Flutter + Dart** для iOS и Android.

Технические решения:

- REST API по OpenAPI из [../api/](../api/).
- JWT access/refresh tokens.
- Защищённое хранение токенов через `flutter_secure_storage` или эквивалент.
- Push через FCM/APNs с регистрацией токена в `registerPushToken`.
- Карта трассы через согласованный Flutter-плагин карт; текстовый fallback обязателен.
- Сетевые мутации офлайн запрещены.

## Экраны

| ID | Экран / шторка | ТЗ |
| :-- | :-- | :-- |
| SCR-001 | Регистрация / вход | [SCR-001-registration.md](SCR-001-registration.md) |
| SCR-002 | Список заездов | [SCR-002-slot-list.md](SCR-002-slot-list.md) |
| BS-001 | Фильтры | [BS-001-filters.md](BS-001-filters.md) |
| SCR-003 | Карточка заезда | [SCR-003-slot-card.md](SCR-003-slot-card.md) |
| SCR-004 | Оформление записи | [SCR-004-booking.md](SCR-004-booking.md) |
| BS-002 | Успех записи | [BS-002-booking-success.md](BS-002-booking-success.md) |
| SCR-005 | Мои записи | [SCR-005-my-bookings.md](SCR-005-my-bookings.md) |
| SCR-006 | Детали брони | [SCR-006-booking-details.md](SCR-006-booking-details.md) |
| BS-003 | Подтверждение отмены | [BS-003-cancel-confirm.md](BS-003-cancel-confirm.md) |
| BS-004 | Карта трассы | [BS-004-track-map.md](BS-004-track-map.md) |
| SCR-007 | Профиль | [SCR-007-profile.md](SCR-007-profile.md) |

## Переиспользуемые логики

См. [09_Логики/_INDEX.md](09_Логики/_INDEX.md): OTP, доступность мест, цена, отмена, фильтры, карта, push, состояния экранов.
