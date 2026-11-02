import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/india_locations.dart';
import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/services_catalog.dart';
import '../domain/profile_models.dart';
import '../providers/profile_provider.dart';
import '../../verification/domain/verification_state.dart';
import '../../verification/providers/verification_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  bool _refreshOnShow = true;
  bool _saving = false;
  List<IndiaState> _locations = const [];
  String? _selectedState;
  String? _selectedCity;
  Set<String> _selectedSkillIds = {};

  String _identityOf(AuthState auth) {
    if (auth is AuthAuthenticated) {
      return '${auth.session.accessToken}|${auth.session.user?.id ?? ''}|${auth.session.user?.phone ?? ''}';
    }
    return auth.runtimeType.toString();
  }

  void _applyProfile(WorkerProfile profile) {
    _name.text = profile.name;
    _selectedSkillIds = {
      for (final skill in profile.skills) skill.categoryId,
    };
    _applyLocation(profile.city);
  }

  void _applyLocation(String stored) {
    var (state, city) = IndiaLocations.splitStoredCity(stored);
    if (state == null && city != null && _locations.isNotEmpty) {
      state = IndiaLocations.stateForCity(city, _locations);
    }
    _selectedState = state;
    _selectedCity = city;
  }

  void _syncSkillNames(List<ServiceCategoryOption> catalog) {
    if (catalog.isEmpty) return;
    final known = {for (final option in catalog) option.id};
    final profile = ref.read(profileProvider);
    final names = {
      profile.skill.trim().toLowerCase(),
      for (final skill in profile.skills) skill.name.trim().toLowerCase(),
    }..remove('');
    final next = {..._selectedSkillIds}..removeWhere((id) => !known.contains(id));
    for (final option in catalog) {
      if (names.contains(option.name.toLowerCase())) {
        next.add(option.id);
      }
    }
    if (next != _selectedSkillIds) {
      setState(() => _selectedSkillIds = next);
    }
  }

  void _clearFields() {
    _name.clear();
    _selectedSkillIds = {};
    _selectedState = null;
    _selectedCity = null;
  }

  List<String> get _citiesForState {
    if (_selectedState == null) return const [];
    IndiaState? match;
    for (final state in _locations) {
      if (state.name == _selectedState) {
        match = state;
        break;
      }
    }
    final cities = [...?match?.cities];
    if (_selectedCity != null &&
        _selectedCity!.isNotEmpty &&
        !cities.contains(_selectedCity)) {
      cities.insert(0, _selectedCity!);
    }
    return cities;
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _name = TextEditingController(text: profile.name);
    _applyProfile(profile);
    unawaited(IndiaLocations.load().then((list) {
      if (!mounted) return;
      setState(() {
        _locations = list;
        _applyLocation(ref.read(profileProvider).city);
      });
    }));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(servicesCatalogProvider);
    await ref.read(profileProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (_identityOf(previous ?? const AuthUnknown()) != _identityOf(next)) {
        _clearFields();
        if (next is AuthAuthenticated) {
          unawaited(ref.read(profileProvider.notifier).refresh());
        }
      }
    });
    ref.listen<WorkerProfile>(profileProvider, (previous, next) {
      setState(() => _applyProfile(next));
    });
    ref.listen<AsyncValue<List<ServiceCategoryOption>>>(
      servicesCatalogProvider,
      (previous, next) {
        next.whenData(_syncSkillNames);
      },
    );

    final onProfile = GoRouterState.of(context).matchedLocation == '/profile';
    if (onProfile && _refreshOnShow) {
      _refreshOnShow = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(ref.read(profileProvider.notifier).refresh());
      });
    } else if (!onProfile) {
      _refreshOnShow = true;
    }

    final profile = ref.watch(profileProvider);
    final verification = ref.watch(verificationProvider);
    final catalog = ref.watch(servicesCatalogProvider);
    final initials = profile.name.isEmpty
        ? '?'
        : profile.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase();
    final headerSkills = profile.skills.isNotEmpty
        ? profile.skills
        : [
            if (profile.skill.isNotEmpty)
              WorkerSkillChoice(categoryId: profile.skill, name: profile.skill),
          ];

    return SkyScaffold(
      title: 'profile.title'.tr(),
      trailing: CircleIconButton(
        icon: Icons.refresh_rounded,
        onPressed: () => unawaited(_refresh()),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          SkyCard(
            entranceIndex: 0,
            child: Row(
              children: [
                NameAvatar(
                  name: profile.name,
                  initials: initials,
                  size: 64,
                  borderRadius: 12,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        profile.phone,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      if (headerSkills.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final skill in headerSkills.take(3))
                              SkyChip(
                                label: skill.name,
                                emoji: ServiceLooks.of(skill.name).emoji,
                                color: ServiceLooks.of(skill.name).color,
                              ),
                            if (headerSkills.length > 3)
                              SkyChip(
                                label: '+${headerSkills.length - 3}',
                                color: AppColors.teal,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SkyCard(
            entranceIndex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.teal, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Trust & Skill Badges',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (verification.badgeState == 'ACTIVE'
                                ? AppColors.teal
                                : AppColors.gold)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        verification.badgeState,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: verification.badgeState == 'ACTIVE'
                              ? AppColors.teal
                              : AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _BadgeChip(
                      label: 'Identity Verified',
                      icon: Icons.badge_outlined,
                      color: AppColors.navy,
                    ),
                    if (verification.isProbation)
                      const _BadgeChip(
                        label: 'Community Verified — Probation',
                        icon: Icons.shield_outlined,
                        color: AppColors.gold,
                      )
                    else if (verification.status ==
                            VerificationStatus.communityVerified ||
                        verification.status ==
                            VerificationStatus.trustedWorker)
                      const _BadgeChip(
                        label: 'Community Verified',
                        icon: Icons.verified_user_outlined,
                        color: AppColors.teal,
                      ),
                    if (profile.certifications
                        .any((c) => c.status == CertificationStatus.approved))
                      const _BadgeChip(
                        label: 'Certificate Verified',
                        icon: Icons.workspace_premium_outlined,
                        color: AppColors.primary,
                      ),
                    if (verification.status == VerificationStatus.trustedWorker)
                      const _BadgeChip(
                        label: 'Trusted Worker',
                        icon: Icons.star_rounded,
                        color: AppColors.gold,
                      ),
                  ],
                ),
                if (verification.isProbation) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Probation (${verification.probationJobCount}/${verification.probationJobCountRequired} jobs)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Cap: ₹${verification.probationJobValueCap.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: verification.probationJobCountRequired > 0
                          ? (verification.probationJobCount /
                                  verification.probationJobCountRequired)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: AppColors.border,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.teal),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SkyCard(
            entranceIndex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'profile.name'.tr(),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${'profile.phone'.tr()}:  ${profile.phone}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
                const Divider(height: 1),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'profile.state'.tr(),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedState,
                      isExpanded: true,
                      hint: Text('profile.selectState'.tr()),
                      items: [
                        if (_selectedState != null &&
                            !_locations.any((s) => s.name == _selectedState))
                          DropdownMenuItem(
                            value: _selectedState,
                            child: Text(_selectedState!),
                          ),
                        for (final state in _locations)
                          DropdownMenuItem(
                            value: state.name,
                            child: Text(state.name),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                          _selectedCity = null;
                        });
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'profile.city'.tr(),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      hint: Text('profile.selectCity'.tr()),
                      items: [
                        for (final city in _citiesForState)
                          DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          ),
                      ],
                      onChanged: _selectedState == null
                          ? null
                          : (value) {
                              setState(() => _selectedCity = value);
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SkyCard(
            entranceIndex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile.skills'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'profile.skillsHint'.tr(),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                catalog.when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'profile.skillsEmpty'.tr(),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < categories.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          CheckboxListTile(
                            value: _selectedSkillIds.contains(categories[i].id),
                            onChanged: (checked) {
                              setState(() {
                                final next = {..._selectedSkillIds};
                                if (checked == true) {
                                  next.add(categories[i].id);
                                } else {
                                  next.remove(categories[i].id);
                                }
                                _selectedSkillIds = next;
                              });
                            },
                            title: Text(categories[i].name),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'profile.skillsEmpty'.tr(),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PressScale(
            enabled: !_saving,
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final city = _selectedCity?.trim() ?? '';
                      if (city.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('profile.selectCity'.tr())),
                        );
                        return;
                      }
                      setState(() => _saving = true);
                      try {
                        await ref.read(profileProvider.notifier).save(
                              name: _name.text.trim(),
                              city: city,
                              stateName: _selectedState,
                              selectedSkillIds: _selectedSkillIds,
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('profile.saved'.tr())),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text('profile.saveProfile'.tr()),
            ),
          ),
          const SizedBox(height: 16),
          SkyCard(
            entranceIndex: 3,
            padding: EdgeInsets.zero,
            onTap: () => context.push('/language?from=settings'),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.language, color: AppColors.teal),
              ),
              title: Text('language.settingsTitle'.tr()),
              subtitle: Text('language.settingsHint'.tr()),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 16),
          SkyCard(
            entranceIndex: 4,
            padding: EdgeInsets.zero,
            onTap: () => context.push('/profile/welfare'),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.teal,
                ),
              ),
              title: Text('welfare.title'.tr()),
              subtitle: Text('profile.welfareHint'.tr()),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'profile.certifications'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _upload(context),
                icon: const Icon(Icons.upload_file_outlined),
                label: Text('profile.upload'.tr()),
              ),
            ],
          ),
          ...profile.certifications.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CertTile(
                  key: ValueKey(entry.value.id),
                  cert: entry.value,
                  entranceIndex: entry.key,
                ),
              )),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            child: Text('profile.logout'.tr()),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _upload(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.upload'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'profile.documentName'.tr(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          PressScale(
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text('common.add'.tr()),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await ref.read(profileProvider.notifier).uploadCertification(name);
  }
}

class _CertTile extends StatelessWidget {
  const _CertTile({
    super.key,
    required this.cert,
    this.entranceIndex = 0,
  });

  final Certification cert;
  final int entranceIndex;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (cert.status) {
      CertificationStatus.pending => (
          'profile.statusPending'.tr(),
          AppColors.gold,
        ),
      CertificationStatus.approved => (
          'profile.statusApproved'.tr(),
          AppColors.teal,
        ),
      CertificationStatus.rejected => (
          'profile.statusRejected'.tr(),
          AppColors.danger,
        ),
    };

    return SkyCard(
      entranceIndex: entranceIndex,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.description_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (cert.rejectReason != null)
                  Text(
                    cert.rejectReason!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          SkyChip(
            label: label,
            color: color,
            filled: cert.status == CertificationStatus.approved,
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
