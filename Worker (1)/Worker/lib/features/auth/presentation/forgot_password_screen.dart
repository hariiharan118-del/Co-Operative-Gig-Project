import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialPhone = ''});

  final String initialPhone;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _phone;
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _codeSent = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String get _e164 {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    return '+91$digits';
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final debugOtp =
          await ref.read(authProvider.notifier).requestPasswordReset(_e164);
      if (!mounted) return;
      if (debugOtp != null && debugOtp.isNotEmpty) {
        _otp.text = debugOtp;
      }
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.forgotSent'.tr())),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).resetPassword(
            phone: _e164,
            otp: _otp.text.trim(),
            newPassword: _password.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.forgotUpdated'.tr())),
      );
      context.go('/login');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final compact = MediaQuery.sizeOf(context).height < 720;
    return Scaffold(
      backgroundColor: AppColors.splash,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    compact ? 4 : 8,
                    32,
                    compact ? 12 : 18,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.headingOnTeal,
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/login');
                            }
                          },
                        ),
                      ),
                      BrandMark(size: compact ? 56 : 64),
                      SizedBox(height: compact ? 10 : 14),
                      Text(
                        'auth.forgotTitle'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.headingOnTeal,
                          fontSize: compact ? 20 : 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'auth.forgotSubtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedOnTeal,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: AppColors.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.sheet),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, 28, 24, 20 + inset),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null) ...[
                              AlertBanner(
                                title: 'auth.invalidCredentials'.tr(),
                                body: _error!,
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: _codeSent
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              enabled: !_busy && !_codeSent,
                              onFieldSubmitted:
                                  _codeSent ? null : (_) => _sendCode(),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                labelText: 'auth.phoneLabel'.tr(),
                                hintText: 'auth.phoneHint'.tr(),
                                prefixIcon: const Icon(
                                  Icons.phone,
                                  color: AppColors.primary,
                                ),
                                prefixText: '+91  ',
                              ),
                              validator: (value) {
                                final digits = (value ?? '')
                                    .replaceAll(RegExp(r'\D'), '');
                                if (digits.length != 10) {
                                  return 'auth.invalidPhone'.tr();
                                }
                                return null;
                              },
                            ),
                            if (_codeSent) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _otp,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                enabled: !_busy,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'auth.forgotCodeLabel'.tr(),
                                  prefixIcon: const Icon(
                                    Icons.pin_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                                validator: (value) {
                                  if (!_codeSent) return null;
                                  if ((value ?? '').trim().length != 6) {
                                    return 'auth.invalidOtp'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.next,
                                enabled: !_busy,
                                decoration: InputDecoration(
                                  labelText: 'auth.forgotNewPassword'.tr(),
                                  hintText: 'auth.passwordHint'.tr(),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (!_codeSent) return null;
                                  if ((value ?? '').length < 8) {
                                    return 'auth.invalidPasswordLength'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirm,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submitNewPassword(),
                                enabled: !_busy,
                                decoration: InputDecoration(
                                  labelText: 'auth.forgotConfirmPassword'.tr(),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.primary,
                                  ),
                                ),
                                validator: (value) {
                                  if (!_codeSent) return null;
                                  if (value != _password.text) {
                                    return 'auth.passwordMismatch'.tr();
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy ? null : _sendCode,
                                  child: Text('auth.forgotResend'.tr()),
                                ),
                              ),
                            ] else
                              const SizedBox(height: 18),
                            PressScale(
                              enabled: !_busy,
                              child: FilledButton(
                                onPressed: _busy
                                    ? null
                                    : (_codeSent
                                        ? _submitNewPassword
                                        : _sendCode),
                                child: Text(
                                  (_codeSent
                                          ? 'auth.forgotSubmit'
                                          : 'auth.forgotSendCode')
                                      .tr(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_busy)
            VerifyingOverlay(
              title: (_codeSent ? 'auth.updatingPassword' : 'auth.resetting')
                  .tr(),
              body: 'auth.verifyingBody'.tr(),
            ),
        ],
      ),
    );
  }
}
