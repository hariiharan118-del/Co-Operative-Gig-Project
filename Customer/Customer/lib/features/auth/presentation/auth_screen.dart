import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';
import '../providers/auth_provider.dart';

enum _AuthMode { login, register }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _AuthMode _mode = _AuthMode.login;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isRegister => _mode == _AuthMode.register;

  String get _e164 {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '+91$digits';
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notifier = ref.read(authProvider.notifier);
      if (_isRegister) {
        await notifier.register(
          phone: _e164,
          name: _nameController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await notifier.login(
          phone: _e164,
          password: _passwordController.text,
        );
      }
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
                  padding: EdgeInsets.fromLTRB(32, compact ? 12 : 20, 32, compact ? 12 : 18),
                  child: Column(
                    children: [
                      BrandMark(size: compact ? 56 : 76),
                      SizedBox(height: compact ? 10 : 18),
                      Text(
                        'auth.welcomeTitle'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.headingOnTeal,
                          fontSize: compact ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'auth.welcomeSubtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedOnTeal,
                          fontSize: 14,
                          height: 1.4,
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
                          Text(
                            (_isRegister
                                    ? 'auth.registerTitle'
                                    : 'auth.signInTitle')
                                .tr(),
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AuthModeToggle(
                            mode: _mode,
                            onChanged: _switchMode,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            AlertBanner(
                              title: 'auth.invalidCredentials'.tr(),
                              body: _error!,
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
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
                          AnimatedSize(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            alignment: Alignment.topCenter,
                            child: _isRegister
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: TextFormField(
                                      controller: _nameController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'auth.nameLabel'.tr(),
                                        hintText: 'auth.nameHint'.tr(),
                                        prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (!_isRegister) return null;
                                        if ((value ?? '').trim().isEmpty) {
                                          return 'auth.invalidName'.tr();
                                        }
                                        return null;
                                      },
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'auth.passwordLabel'.tr(),
                              hintText: 'auth.passwordHint'.tr(),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.primary,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
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
                              if (password.isEmpty) {
                                return 'auth.passwordRequired'.tr();
                              }
                              if (_isRegister && password.length < 8) {
                                return 'auth.invalidPassword'.tr();
                              }
                              return null;
                            },
                          ),
                          if (!_isRegister)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => context.go(
                                          '/forgot-password',
                                          extra: _phoneController.text,
                                        ),
                                child: Text('auth.forgotPassword'.tr()),
                              ),
                            )
                          else
                            const SizedBox(height: 18),
                          PressScale(
                            enabled: !_busy,
                            child: FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: Text(
                                (_isRegister
                                        ? 'auth.registerCta'
                                        : 'auth.loginCta')
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
              title: (_isRegister ? 'auth.registering' : 'auth.verifying').tr(),
              body: 'auth.verifyingBody'.tr(),
            ),
        ],
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tab(
            label: 'auth.loginTab'.tr(),
            selected: mode == _AuthMode.login,
            onTap: () => onChanged(_AuthMode.login),
          ),
          _tab(
            label: 'auth.registerTab'.tr(),
            selected: mode == _AuthMode.register,
            onTap: () => onChanged(_AuthMode.register),
          ),
        ],
      ),
    );
  }

  Widget _tab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
