# BUG-003. Чипы в карточке заезда переполняли строку на узком экране

## Симптом

На SCR-002 в списке заездов чипы (`ChipText`) внутри `SlotCard` давали множественные ошибки `RenderFlex overflowed by X pixels on the right` (стек: `slot_card.dart:169`, `Row` внутри чипа). Особенно на длинных подписях маршала с рейтингом (`Имя · ★ 4.8 (127)`). Дополнительно на SCR-007 при крупном тексте — предупреждения `ListTile` о переполнении subtitle.

## Требования

- `01-analysis/5-mobile-app-spec/SCR-002-slot-list.md` — состав карточки: тип трассы, маршал, места, прокат.
- `01-analysis/3-design-brief/SCR-002-slot-list.md` — поля карточки заезда в списке.
- `01-analysis/2-requirements/functional-requirements.md` — **FR-9a**: карточка слота с маршалом, местами, прокатом.
- `01-analysis/2-requirements/non-functional-requirements.md` — **NFR-25 (A11y)**: системный размер шрифта.

## Причина

`ChipText` размещался в `Wrap` с ограниченной шириной (~166 px на половину карточки), но `Row` с иконкой и `Text` без `Flexible` / `ellipsis` требовал больше места, чем доступно. `ListTile` в профиле не обрезал длинные subtitle.

## Исправление

- `client/lib/features/slots/presentation/slot_card.dart` — текст чипа в `Flexible` с `maxLines: 1` и `TextOverflow.ellipsis`.
- `client/lib/features/profile/presentation/profile_screen.dart` — `maxLines` + `overflow: TextOverflow.ellipsis` для subtitle в `ListTile`.
- `client/test/widgets/slot_card_test.dart` — автотест на overflow.

## Промпты

```
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞══
A RenderFlex overflowed by 19 pixels on the right.
Row:file:///.../client/lib/features/slots/presentation/slot_card.dart:169:14
...
Another exception was thrown: A RenderFlex overflowed by 6.9 pixels on the right.
...
Another exception was thrown: Leading widget consumes the entire tile width ...
```

## Проверка вручную

1. `cd client && flutter test test/widgets/slot_card_test.dart` — тест проходит.
2. `flutter run -d chrome` → список заездов на узком окне (320 px) или с увеличенным текстом.
3. Чипы не дают жёлто-чёрных полос; длинные имена маршалов обрезаются многоточием.
4. Профиль → плитки «Имя», «Телефон», «Уведомления» без overflow.

Автотест: `client/test/widgets/slot_card_test.dart` — `SlotCard does not overflow on small viewport and large text`.
