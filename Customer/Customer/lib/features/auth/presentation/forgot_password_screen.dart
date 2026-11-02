import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _phoneController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _codeSent = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;
  String? _debugOtp;

  @override
  void initState() {
    super.initState();
    final digits = (widget.initialPhone ?? '').replaceAll(RegExp(r'\D'), '');
    _phoneController = TextEditingController(
      text: digits.length > 10 ? digits.substring(digits.length - 10) : digits,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _e164 {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '+91$digits';
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge =
          await ref.read(authProvider.notifier).requestPasswordReset(_e164);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _debugOtp = challenge.debugOtp;
        if (_debugOtp != null && _debugOtp!.isNotEmpty) {
          _otpController.text = _debugOtp!;
        }
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).resetPassword(
            phone: _e164,
            otp: _otpController.text.trim(),
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.resetSuccess'.tr())),
      );
      context.go('/login');
    } catch (error) {
      setState(() => _error = error.toString());
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
                          onPressed: () => context.go('/login'),
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
                        (_codeSent
                                ? 'auth.resetCodeSent'
                                : 'auth.forgotSubtitle')
                            .tr(args: [_e164]),
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
                            if (_debugOtp != null && _debugOtp!.isNotEmpty) ...[
                              AlertBanner(
                                title: 'auth.otpLabel'.tr(),
                                body: 'auth.devOtpHint'.tr(args: [_debugOtp!]),
                                tone: AlertTone.info,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_error != null) ...[
                              AlertBanner(
                                title: 'auth.invalidCredentials'.tr(),
                                body: _error!,
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _phoneController,
                              enabled: !_codeSent,
                              keyboardType: TextInputType.phone,
                              textInputAction: _codeSent
                                  ? TextInputAction.next
                                  : TextInputAction.done,
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
                                final digits =
                                    (value ?? '').replaceAll(RegExp(r'\D'), '');
                                if (digits.length != 10) {
                                  return 'auth.invalidPhone'.tr();
                                }
                                return null;
                              },
                            ),
                            if (_codeSent) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(8),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'auth.otpLabel'.tr(),
                                  hintText: 'auth.otpHint'.tr(),
                                  prefixIcon: const Icon(
                                    Icons.pin_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                                validator: (value) {
                                  final length = (value ?? '').trim().length;
                                  if (length < 4 || length > 8) {
                                    return 'auth.invalidOtp'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'auth.newPasswordLabel'.tr(),
                                  hintText: 'auth.passwordHint'.tr(),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  final password = value ?? '';
                                  if (password.length < 8) {
                                    return 'auth.invalidPassword'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _resetPassword(),
                                decoration: InputDecoration(
                                  labelText: 'auth.confirmPasswordLabel'.tr(),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.primary,
                                  ),
                                ),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'auth.passwordMismatch'.tr();
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy ? null : _sendCode,
                                  child: Text('auth.resendCode'.tr()),
                                ),
                              ),
                            ] else
                              const SizedBox(height: 18),
                            PressScale(
                              enabled: !_busy,
                              child: FilledButton(
                                onPressed: _busy
                                    ? null
                                    : (_codeSent ? _resetPassword : _sendCode),
                                child: Text(
                                  (_codeSent
                                          ? 'auth.resetCta'
                                          : 'auth.sendResetCode')
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
              title: (_codeSent
                      ? 'auth.updatingPassword'
                      : 'auth.resetting')
                  .tr(),
              body: 'auth.verifyingBody'.tr(),
            ),
        ],
      ),
    );
  }
}
