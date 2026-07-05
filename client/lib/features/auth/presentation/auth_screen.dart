import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/load_state.dart';
import '../../../core/ui/snackbars.dart';

/// SCR-001 — Регистрация / вход (OTP, LOGIC-001).
///
/// Steps: phone -> code (+ name for a new client). On success the router
/// redirect returns the user to [returnTo] (auth gate return intent).
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    this.returnTo,
    super.key,
  });

  final String? returnTo;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthStep { phone, code }

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController(text: '+7');
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  _AuthStep _step = _AuthStep.phone;
  ActionStatus _status = ActionStatus.idle;
  String? _inlineError;
  bool _nameRequired = false;
  bool _consentAccepted = false;

  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _phone => _phoneController.text.trim();

  bool get _isPhoneValid => RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(_phone);

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSecondsLeft -= 1;
        if (_resendSecondsLeft <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    if (!_isPhoneValid) {
      setState(() => _inlineError = 'Введите телефон в формате +79991234567');
      return;
    }
    setState(() {
      _status = ActionStatus.submitting;
      _inlineError = null;
    });

    try {
      await AppScope.of(context).authRepository.sendOtp(phone: _phone);
      if (!mounted) return;
      setState(() {
        _step = _AuthStep.code;
        _status = ActionStatus.idle;
      });
      _startResendCountdown(60);
    } on Object catch (error) {
      if (!mounted) return;
      final failure = toAppFailure(error);
      setState(() {
        _status = ActionStatus.idle;
        _inlineError = failure.uiMessage;
      });
      if (failure.code == ApiErrorCode.rateLimit && failure.retryAfter != null) {
        // Rate limit on send: user can go to code entry only after retry_after.
        _startResendCountdown(failure.retryAfter!);
      }
    }
  }

  Future<void> _resend() async {
    await _sendOtp();
    if (!mounted || _inlineError != null) {
      return;
    }
    showAppSnack(context, 'Код отправлен повторно');
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 4) {
      setState(() => _inlineError = 'Введите код из SMS');
      return;
    }
    final name = _nameController.text.trim();
    if (_nameRequired && name.isEmpty) {
      setState(() => _inlineError = 'Для первого входа укажите имя');
      return;
    }
    if (name.isNotEmpty && !_consentAccepted) {
      setState(
        () => _inlineError =
            'Для регистрации подтвердите согласие с условиями и политикой',
      );
      return;
    }

    setState(() {
      _status = ActionStatus.submitting;
      _inlineError = null;
    });

    final deps = AppScope.of(context);
    try {
      final pair = await deps.authRepository.verifyOtp(
        phone: _phone,
        code: code,
        name: name.isEmpty ? null : name,
      );
      await deps.sessionController.signIn(pair);
      // Navigation happens via the router redirect (return intent).
    } on Object catch (error) {
      if (!mounted) return;
      final failure = toAppFailure(error);
      setState(() {
        _status = ActionStatus.idle;
        if (failure.code == ApiErrorCode.validationError &&
            failure.message.toLowerCase().contains('name')) {
          // New client: the server demands a name.
          _nameRequired = true;
          _inlineError = 'Вы у нас впервые — укажите имя, чтобы зарегистрироваться';
        } else {
          _inlineError = failure.uiMessage;
        }
      });
      if (failure.code == ApiErrorCode.rateLimit && failure.retryAfter != null) {
        _startResendCountdown(failure.retryAfter!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = _status == ActionStatus.submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'К заездам',
          onPressed: () => context.go('/slots'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ApexSpacing.lg),
          children: [
            Text(
              _step == _AuthStep.phone
                  ? 'Введите номер телефона'
                  : 'Введите код из SMS',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ApexSpacing.sm),
            Text(
              _step == _AuthStep.phone
                  ? 'Отправим SMS с кодом подтверждения.'
                  : 'Код отправлен на $_phone',
            ),
            const SizedBox(height: ApexSpacing.lg),
            if (_step == _AuthStep.phone) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                enabled: !submitting,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+79991234567',
                ),
                onSubmitted: (_) => _sendOtp(),
              ),
            ] else ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                autofocus: true,
                enabled: !submitting,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'Код из SMS',
                  counterText: '',
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: ApexSpacing.md),
              TextField(
                controller: _nameController,
                enabled: !submitting,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText:
                      _nameRequired ? 'Имя (обязательно)' : 'Имя (для новых клиентов)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: ApexSpacing.sm),
              CheckboxListTile(
                value: _consentAccepted,
                onChanged: submitting
                    ? null
                    : (value) =>
                        setState(() => _consentAccepted = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Соглашаюсь с условиями обслуживания и политикой обработки персональных данных',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
            if (_inlineError != null) ...[
              const SizedBox(height: ApexSpacing.md),
              Text(
                _inlineError!,
                style: const TextStyle(color: ApexColors.trackRed),
              ),
            ],
            const SizedBox(height: ApexSpacing.lg),
            if (_step == _AuthStep.phone)
              FilledButton(
                onPressed: submitting || _resendSecondsLeft > 0 ? null : _sendOtp,
                child: Text(
                  submitting
                      ? 'Отправляем…'
                      : _resendSecondsLeft > 0
                          ? 'Повтор через $_resendSecondsLeft с'
                          : 'Получить код',
                ),
              )
            else ...[
              FilledButton(
                onPressed: submitting ? null : _verify,
                child: Text(submitting ? 'Проверяем…' : 'Войти'),
              ),
              const SizedBox(height: ApexSpacing.sm),
              TextButton(
                onPressed: submitting || _resendSecondsLeft > 0 ? null : _resend,
                child: Text(
                  _resendSecondsLeft > 0
                      ? 'Отправить код ещё раз через $_resendSecondsLeft с'
                      : 'Отправить код ещё раз',
                ),
              ),
              TextButton(
                onPressed: submitting
                    ? null
                    : () => setState(() {
                          _step = _AuthStep.phone;
                          _codeController.clear();
                          _inlineError = null;
                          _nameRequired = false;
                        }),
                child: const Text('Изменить номер'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
