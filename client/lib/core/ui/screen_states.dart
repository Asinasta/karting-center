import 'package:flutter/material.dart';

import '../theme/apex_tokens.dart';

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ApexSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ApexSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: ApexSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ApexSpacing.md),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineStaleBanner extends StatelessWidget {
  const OfflineStaleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ApexColors.signalAmber.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(ApexSpacing.sm),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: ApexSpacing.sm),
            const Expanded(
              child: Text('Показаны сохранённые данные, они могли устареть.'),
            ),
          ],
        ),
      ),
    );
  }
}
