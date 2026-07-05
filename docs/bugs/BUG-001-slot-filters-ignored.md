# BUG-001. Клиент игнорировал фильтры при запросе `GET /slots`

## Симптом

На экране SCR-002 кнопка «Фильтры» только переключала флаг `only_available` локально. Параметры `date_from`, `date_to`, `track_config_type[]`, `marshal_id[]` из BS-001 / LOGIC-005 **не отправлялись** в API. После применения фильтров по типу трассы или маршалу список не менялся.

## Требования

- `01-analysis/5-mobile-app-spec/BS-001-filters.md` — фильтры по периоду, типу трассы, маршалу, «только свободные».
- `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-005_Фильтрация-слотов.md` — параметры API: `date_from`, `date_to`, `track_config_type[]`, `marshal_id[]`, `only_available`.
- `01-analysis/api/slots/api.yaml` — `listSlots` query parameters.

## Причина

`ApiSlotRepository.listSlots` принимал только `onlyAvailable: bool`. Экран `SlotListScreen` не имел bottom sheet BS-001 и не строил query из `SlotFilter`.

## Исправление

- Добавлен `SlotFilter` (`client/lib/features/slots/domain/slot_filter.dart`) с методом `toQuery()`.
- Реализован `filters_sheet.dart` (BS-001): период, тип трассы, маршалы из `GET /marshals`, переключатель «Только свободные», «Применить» / «Сбросить».
- `ApiSlotRepository.listSlots` принимает `SlotFilter` и передаёт query в `ApiClient.get`.
- `SlotListScreen` открывает sheet и перезагружает список с новым фильтром.

## Промпты

```
Продолжить реализацию по порядку из плана: FL-05: фильтры.
Все API-модели и поля сверяй с 01-analysis/api.
```

Полный контекст: `docs/prompts/chat-06-flutter-client-development.txt`.

## Проверка вручную

1. Открыть список заездов.
2. Нажать «Фильтры» → выбрать «Только свободные» → «Применить».
3. В списке остаются только слоты со статусом «Доступен».
4. Сбросить фильтры → снова видны все слоты за 7 дней.

Автотест: `client/test/data/repositories_test.dart` — `listSlots builds filter query`.

## Коммит

`fix(client): apply slot filters to GET /slots query (BUG-001)`
