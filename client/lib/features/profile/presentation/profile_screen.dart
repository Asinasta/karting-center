import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/apex_dialog.dart';
import '../../../core/ui/load_state.dart';
import '../../../core/ui/screen_states.dart';
import '../../../core/ui/snackbars.dart';
import '../domain/profile_models.dart';
import 'loyalty_card.dart';
import 'phone_change_sheet.dart';

/// SCR-007 — Профиль (FL-13). Protected by the router auth gate.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  LoadState<Profile> _state = const Loading();
  ActionStatus _action = ActionStatus.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final deps = AppScope.of(context);
    setState(() => _state = const Loading());
    try {
      final profile = await deps.profileRepository.getProfile();
      if (!mounted) return;
      deps.profileCache.store(profile);
      deps.sessionController.updateClient(profile);
      // Push token re-registration retry point (FL-13/FL-14).
      deps.pushService.syncToken();
      setState(() => _state = Content(profile));
    } on Object catch (error) {
      if (!mounted) return;
      final failure = toAppFailure(error);
      final cached = deps.profileCache.value;
      setState(() {
        if (failure.isNetwork && cached != null) {
          _state = OfflineStale(cached);
        } else {
          _state = Failure(failure);
        }
      });
    }
  }

  Future<void> _editName(Profile profile) async {
    final controller = TextEditingController(text: profile.name);
    final newName = await showApexDialog<String>(
      context: context,
      builder: (dialogContext) {
        return ApexDialogScaffold(
          title: 'Имя',
          body: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Ваше имя'),
          ),
          actions: [
            ApexDialogAction(
              label: 'Сохранить',
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
            ),
            ApexDialogAction(
              label: 'Отмена',
              kind: ApexDialogActionKind.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
    if (newName == null || newName.isEmpty || newName == profile.name || !mounted) {
      return;
    }

    final deps = AppScope.of(context);
    setState(() => _action = ActionStatus.submitting);
    try {
      // PATCH /profile sends only the name — phone never goes here.
      final updated = await deps.profileRepository.updateProfile(name: newName);
      if (!mounted) return;
      deps.profileCache.store(updated);
      deps.sessionController.updateClient(updated);
      setState(() {
        _action = ActionStatus.idle;
        _state = Content(updated);
      });
      showAppSnack(context, 'Имя обновлено');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _action = ActionStatus.idle);
      showFailureSnack(context, toAppFailure(error));
    }
  }

  Future<void> _changePhone(Profile profile) async {
    final updated = await showPhoneChangeSheet(context, profile);
    if (updated != null && mounted) {
      final deps = AppScope.of(context);
      deps.profileCache.store(updated);
      deps.sessionController.updateClient(updated);
      setState(() => _state = Content(updated));
      showAppSnack(context, 'Телефон обновлён');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы сможете войти снова по номеру телефона.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: ApexButtonStyles.outlinedRed,
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ApexButtonStyles.filledRed,
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final deps = AppScope.of(context);
    deps.profileCache.clear();
    deps.bookingsCache.clear();
    await deps.sessionController.logout();
    if (mounted) {
      context.go('/slots');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Активные брони будут отменены по обычным правилам отмены. '
          'Действие необратимо.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: ApexButtonStyles.outlinedRed,
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ApexButtonStyles.filledRed,
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final deps = AppScope.of(context);
    setState(() => _action = ActionStatus.submitting);
    try {
      await deps.profileRepository.deleteAccount();
      if (!mounted) return;
      // Tokens are cleared only after the API confirmed deletion (SCR-007).
      deps.profileCache.clear();
      deps.bookingsCache.clear();
      await deps.sessionController.logout();
      if (mounted) {
        context.go('/auth');
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _action = ActionStatus.idle);
      showFailureSnack(context, toAppFailure(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: switch (_state) {
        Loading<Profile>() => const LoadingStateView(),
        Failure<Profile>(error: final error) => ErrorStateView(
            message: error.uiMessage,
            onRetry: _load,
          ),
        OfflineStale<Profile>(data: final profile) => Column(
            children: [
              const OfflineStaleBanner(),
              Expanded(child: _content(profile, readOnly: true)),
            ],
          ),
        Content<Profile>(data: final profile) => _content(profile),
        Empty<Profile>() => const LoadingStateView(),
      },
      bottomNavigationBar: const ApexBottomNavigationBar(currentIndex: 2),
    );
  }

  Widget _content(Profile profile, {bool readOnly = false}) {
    final busy = _action == ActionStatus.submitting;
    final disabled = readOnly || busy;

    return ListView(
      padding: const EdgeInsets.all(ApexSpacing.md),
      children: [
        if (profile.hasLoyalty) ...[
          LoyaltyCard(profile: profile),
          const SizedBox(height: ApexSpacing.md),
        ],
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Имя'),
                subtitle: Text(profile.name),
                trailing: const Icon(Icons.edit_outlined),
                onTap: disabled ? null : () => _editName(profile),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Телефон'),
                subtitle: Text(profile.phone),
                trailing: const Icon(Icons.chevron_right),
                onTap: disabled ? null : () => _changePhone(profile),
              ),
            ],
          ),
        ),
        const SizedBox(height: ApexSpacing.md),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.notifications_outlined),
                title: Text('Уведомления'),
                subtitle: Text('Напоминания об отменах, заездах и оценке маршала'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Условия обслуживания'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAppSnack(
                  context,
                  'Документ появится в продакшн-сборке',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Политика обработки данных'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAppSnack(
                  context,
                  'Документ появится в продакшн-сборке',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ApexSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: disabled ? null : _logout,
            style: ApexButtonStyles.filledRed,
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ),
        const SizedBox(height: ApexSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: disabled ? null : _deleteAccount,
            style: ApexButtonStyles.outlinedRed,
            child: const Text('Удалить аккаунт'),
          ),
        ),
        const SizedBox(height: ApexSpacing.lg),
      ],
    );
  }
}
