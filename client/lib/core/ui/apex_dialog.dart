import 'package:flutter/material.dart';

import '../theme/apex_tokens.dart';

abstract final class ApexDialogSizes {
  static const double compact = 420;
  static const double wide = 520;
}

enum ApexDialogActionKind { primary, secondary, destructive }

class ApexDialogAction {
  const ApexDialogAction({
    required this.label,
    required this.onPressed,
    this.kind = ApexDialogActionKind.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ApexDialogActionKind kind;
  final IconData? icon;
}

/// Centered dialog with unified chrome on mobile, web and desktop.
Future<T?> showApexDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double maxWidth = ApexDialogSizes.compact,
  double? maxHeightFactor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      final maxHeight = maxHeightFactor != null
          ? MediaQuery.sizeOf(dialogContext).height * maxHeightFactor
          : MediaQuery.sizeOf(dialogContext).height * 0.9;

      return Dialog(
        insetPadding: const EdgeInsets.all(ApexSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: builder(dialogContext),
        ),
      );
    },
  );
}

/// Unified dialog layout: title, body, full-width stacked buttons.
class ApexDialogScaffold extends StatelessWidget {
  const ApexDialogScaffold({
    required this.title,
    required this.body,
    this.trailing,
    this.actions = const [],
    this.expandBody = false,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? trailing;
  final List<ApexDialogAction> actions;
  final bool expandBody;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
        ApexSpacing.lg,
        ApexSpacing.lg,
        ApexSpacing.lg,
        ApexSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    final bodyWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: ApexSpacing.lg),
      child: expandBody ? Expanded(child: body) : body,
    );

    final footer = actions.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(
              ApexSpacing.lg,
              ApexSpacing.md,
              ApexSpacing.lg,
              ApexSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: ApexSpacing.sm),
                  _DialogActionButton(action: actions[i]),
                ],
              ],
            ),
          );

    if (expandBody) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          bodyWidget,
          if (footer != null) footer,
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          bodyWidget,
          if (footer != null) footer,
        ],
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({required this.action});

  final ApexDialogAction action;

  @override
  Widget build(BuildContext context) {
    final onPressed = action.onPressed;

    Widget label = Text(action.label);
    if (action.icon != null) {
      label = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, size: 20),
          const SizedBox(width: ApexSpacing.sm),
          Text(action.label),
        ],
      );
    }

    final button = switch (action.kind) {
      ApexDialogActionKind.primary => FilledButton(
          onPressed: onPressed,
          child: label,
        ),
      ApexDialogActionKind.secondary => OutlinedButton(
          onPressed: onPressed,
          style: ApexButtonStyles.outlinedRed,
          child: Text(action.label),
        ),
      ApexDialogActionKind.destructive => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(backgroundColor: ApexColors.trackRed),
          child: Text(action.label),
        ),
    };

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}

Future<bool> showApexConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Отмена',
  bool destructive = false,
}) async {
  final result = await showApexDialog<bool>(
    context: context,
    builder: (dialogContext) => ApexDialogScaffold(
      title: title,
      body: Text(message, style: Theme.of(dialogContext).textTheme.bodyLarge),
      actions: [
        ApexDialogAction(
          label: confirmLabel,
          kind: destructive
              ? ApexDialogActionKind.destructive
              : ApexDialogActionKind.primary,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
        ApexDialogAction(
          label: cancelLabel,
          kind: ApexDialogActionKind.secondary,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
      ],
    ),
  );
  return result ?? false;
}
