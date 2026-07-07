# BUG-002. Карточка лояльности переполняла экран при крупном системном шрифте

## Симптом

На SCR-007 в профиле карточка программы лояльности (`LoyaltyCard`) давала `RenderFlex overflow` на узком viewport (320×480) при увеличенном системном масштабе текста (`TextScaler.linear(2)`). В консоли — жёлто-чёрные полосы overflow; автотест `loyalty_card_test.dart` падал.

## Требования

- `01-analysis/5-mobile-app-spec/SCR-007-profile.md` — карточка лояльности: tier, скидка, число завершённых заездов.
- `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-009_Лояльность.md` — отображение программы лояльности в профиле.
- `01-analysis/2-requirements/non-functional-requirements.md` — **NFR-25 (A11y)**: поддержка системного размера шрифта.
- `01-analysis/3-design-brief/00-foundations.md` — раздел «Доступность».

## Причина

`FittedBox` с `BoxFit.scaleDown` не мог уменьшить текст: внутренний `ConstrainedBox` задавал `maxHeight`, равный высоте текстовой зоны, и `Column` пытался уложиться в ~86 px до масштабирования. Дополнительно compact-режим не включался при `textScale > 1.3`, хотя карточка была почти на пороге высоты.

## Исправление

- `client/lib/features/profile/presentation/loyalty_card.dart`:
  - убран `maxHeight` у `ConstrainedBox` внутри `FittedBox` (оставлен только `maxWidth`);
  - compact-режим включается при `textScale > 1.3`, не только по высоте карточки;
  - `withOpacity` → `withValues(alpha: …)` (deprecation).

## Промпты

```
PS C:\Users\Asinasta\Downloads\karting-center\client> flutter analyze
...
PS C:\Users\Asinasta\Downloads\karting-center\client> flutter test
...
LoyaltyCard does not overflow on small viewport and large text [E]
Expected: null
Actual: FlutterError:<A RenderFlex overflowed by 162 pixels on the bottom.>
```

## Проверка вручную

1. `cd client && flutter test test/widgets/loyalty_card_test.dart` — тест проходит.
2. `flutter run -d chrome`, войти под seed-клиентом → вкладка «Профиль».
3. В DevTools: viewport 320×480, увеличить масштаб текста / zoom.
4. Карточка лояльности отображается без overflow; текст уменьшается, не обрезается с ошибкой.

Автотест: `client/test/widgets/loyalty_card_test.dart` — `LoyaltyCard does not overflow on small viewport and large text`.
