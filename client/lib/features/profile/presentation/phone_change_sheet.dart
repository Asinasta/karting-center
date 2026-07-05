import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/load_state.dart';
import '../domain/profile_models.dart';

/// Phone change OTP flow (SCR-007, LOGIC-001 п.7).
///
/// Sends the code to the new number; the old number stays active until the
/// change is verified. Returns the updated [Profile] on success.
Future<Profile?> showPhoneChangeSheet(BuildContext context, Profile profile) {
  return showModalBottomSheet<Profile>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _PhoneChangeSheet(currentPhone: profile.phone),
    ),
  );
}

enum _Step { phone, code }

class _PhoneChangeSheet extends StatefulWidget {
  const _PhoneChangeSheet({required this.currentPhone});

  final String currentPhone;

  @override
  State<_PhoneChangeSheet> createState() => _PhoneChangeSheetState();
}

class _PhoneChangeSheetState extends State<_PhoneChangeSheet> {
  final _phoneController = TextEditingController(text: '+7');
  final _codeController = TextEditingController();

  _Step _step = _Step.phone;
  ActionStatus _status = ActionStatus.idle;
  String? _inlineError;
  int _resendSecondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _newPhone => _phoneController.text.trim();

  bool get _isPhoneValid => RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(_newPhone);

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _resendSecondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    if (_newPhone == widget.currentPhone) {
      setState(() => _inlineError = 'Это ваш текущий номер');
      return;
    }
    setState(() {
      _status = ActionStatus.submitting;
      _inlineError = null;
    });
    try {
      await AppScope.of(context)
          .profileRepository
          .sendPhoneChangeOtp(newPhone: _newPhone);
      if (!mounted) return;
      setState(() {
        _status = ActionStatus.idle;
        _step = _Step.code;
      });
      _startCountdown(60);
    } on Object catch (error) {
      if (!mounted) return;
      final failure = toAppFailure(error);
      setState(() {
        _status = ActionStatus.idle;
        _inlineError = failure.uiMessage;
      });
      if (failure.code == ApiErrorCode.rateLimit && failure.retryAfter != null) {
        _startCountdown(failure.retryAfter!);
      }
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 4) {
      setState(() => _inlineError = 'Введите код из SMS');
      return;
    }
    setState(() {
      _status = ActionStatus.submitting;
      _inlineError = null;
    });
    try {
      final updated = await AppScope.of(context)
          .profileRepository
          .verifyPhoneChange(newPhone: _newPhone, code: code);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on Object catch (error) {
      if (!mounted) return;
      final failure = toAppFailure(error);
      setState(() {
        _status = ActionStatus.idle;
        _inlineError = failure.uiMessage;
      });
      if (failure.code == ApiErrorCode.rateLimit && failure.retryAfter != null) {
        _startCountdown(failure.retryAfter!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final submitting = _status == ActionStatus.submitting;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ApexSpacing.lg,
          0,
          ApexSpacing.lg,
          ApexSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Смена телефона',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ApexSpacing.sm),
            Text(
              _step == _Step.phone
                  ? 'Текущий номер ${widget.currentPhone} останется активным '
                      'до подтверждения нового.'
                  : 'Код отправлен на $_newPhone',
            ),
            const SizedBox(height: ApexSpacing.md),
            if (_step == _Step.phone)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                enabled: !submitting,
                decoration: const InputDecoration(
                  labelText: 'Новый телефон',
                  hintText: '+79991234567',
                ),
                onSubmitted: (_) => _sendOtp(),
              )
            else
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
            if (_inlineError != null) ...[
              const SizedBox(height: ApexSpacing.sm),
              Text(
                _inlineError!,
                style: const TextStyle(color: ApexColors.trackRed),
              ),
            ],
            const SizedBox(height: ApexSpacing.md),
            if (_step == _Step.phone)
              FilledButton(
                onPressed:
                    submitting || _resendSecondsLeft > 0 ? null : _sendOtp,
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
                child: Text(submitting ? 'Проверяем…' : 'Подтвердить'),
              ),
              TextButton(
                onPressed: submitting || _resendSecondsLeft > 0 ? null : _sendOtp,
                child: Text(
                  _resendSecondsLeft > 0
                      ? 'Отправить код ещё раз через $_resendSecondsLeft с'
                      : 'Отправить код ещё раз',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
