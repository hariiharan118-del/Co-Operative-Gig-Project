import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale/app_languages.dart';
import '../../../core/locale/language_prefs.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';

final languageChosenProvider = StateProvider<bool>((ref) {
  return LanguagePrefs.hasChosen;
});

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    final saved = LanguagePrefs.code;
    _selected = AppLanguages.visible.any((language) => language.code == saved)
        ? saved!
        : AppLanguages.visible.first.code;
  }

  Future<void> _select(AppLanguage language) async {
    setState(() => _selected = language.code);
    await LanguagePrefs.setLanguage(language.code);
    ref.read(languageChosenProvider.notifier).state = true;
    if (!mounted) return;
    await context.setLocale(language.locale);
  }

  Future<void> _continue() async {
    final language = AppLanguages.byCode(_selected) ?? AppLanguages.visible.first;
    if (!LanguagePrefs.hasChosen || LanguagePrefs.code != language.code) {
      await _select(language);
    }
    if (!mounted) return;
    if (widget.fromSettings) {
      if (context.canPop()) context.pop();
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.fromSettings
              ? 'language.settingsTitle'.tr()
              : 'language.title'.tr(),
        ),
        automaticallyImplyLeading: widget.fromSettings,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!widget.fromSettings) ...[
            Text(
              'language.subtitle'.tr(),
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
          for (final language in AppLanguages.visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: _selected == language.code
                    ? AppColors.primarySoft
                    : AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _selected == language.code
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    language.listLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  trailing: Icon(
                    _selected == language.code
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: _selected == language.code
                        ? AppColors.primary
                        : AppColors.muted,
                  ),
                  onTap: () => _select(language),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PressScale(
            child: FilledButton(
              onPressed: _continue,
              child: Text('language.continue'.tr()),
            ),
          ),
        ),
      ),
    );
  }
}
