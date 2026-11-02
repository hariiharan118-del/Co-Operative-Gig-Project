import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api_error.dart';
import '../../../core/device_location.dart';
import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/data/nominatim_geocoder.dart';
import '../../booking/domain/models.dart';
import '../../booking/presentation/pick_location_map_screen.dart';
import '../../booking/providers/booking_providers.dart';
import '../../home/providers/home_providers.dart';
import '../../providers/presentation/deactivate_account_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _name = TextEditingController(text: profile.name);
    _email = TextEditingController(text: profile.email);
    _phone = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileProvider.notifier).save(
            name: _name.text.trim(),
            email: _email.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.saved'.tr())),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    ref.listen(profileProvider, (previous, next) {
      final identityChanged =
          previous?.id != next.id || previous?.phone != next.phone;
      if (identityChanged) {
        _name.text = next.name;
        _email.text = next.email;
        _phone.text = next.phone;
        return;
      }
      if (previous != null && _name.text == previous.name) {
        _name.text = next.name;
      } else if (_name.text.isEmpty && next.name.isNotEmpty) {
        _name.text = next.name;
      }
      if (previous != null && _email.text == previous.email) {
        _email.text = next.email;
      } else if (_email.text.isEmpty && next.email.isNotEmpty) {
        _email.text = next.email;
      }
      if (_phone.text != next.phone) {
        _phone.text = next.phone;
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text('profile.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NameAvatar(
                        name: profile.name,
                        initials: profile.initials,
                        size: 64,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'profile.personalTitle'.tr(),
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.phone.isEmpty
                                  ? 'profile.phoneHint'.tr()
                                  : profile.phone,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    AlertBanner(
                      title: 'auth.invalidCredentials'.tr(),
                      body: _error!,
                    ),
                  ],
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'profile.name'.tr(),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'profile.nameRequired'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'profile.email'.tr(),
                      hintText: 'profile.emailHint'.tr(),
                      prefixIcon: const Icon(Icons.mail_outline),
                    ),
                    validator: (value) {
                      final email = (value ?? '').trim();
                      if (email.isEmpty) return null;
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'profile.invalidEmail'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    readOnly: true,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      labelText: 'profile.phone'.tr(),
                      helperText: 'profile.phoneHint'.tr(),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      suffixIcon: const Icon(Icons.lock_outline, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PressScale(
                    enabled: !_busy,
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text('profile.saveProfile'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/language?from=settings'),
            child: Row(
              children: [
                const IconTile(icon: Icons.language),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'language.settingsTitle'.tr(),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'language.settingsHint'.tr(),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/profile/addresses'),
            child: Row(
              children: [
                const IconTile(icon: Icons.location_on_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile.addresses'.tr(),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'profile.manageAddresses'.tr(),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/providers'),
            child: Row(
              children: [
                const IconTile(icon: Icons.verified_user_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'providers.queueTitle'.tr(),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/onboarding/region'),
            child: Row(
              children: [
                const IconTile(icon: Icons.map_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'providers.regionTitle'.tr(),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => showDeactivateAccountSheet(context),
            child: Text('providers.deactivateTitle'.tr()),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            child: Text('profile.logout'.tr()),
          ),
        ],
      ),
    );
  }
}

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(savedAddressesProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text('profile.addresses'.tr())),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/profile/addresses/new'),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: addresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final address = addresses[index];
          return Card(
            child: ListTile(
              title: Text(address.label),
              subtitle: Text(address.fullLine),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.push('/profile/addresses/${address.id}/edit'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref
                        .read(savedAddressesProvider.notifier)
                        .remove(address.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId});

  final String? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _line1;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  SavedAddress? _existing;
  final _geocoder = NominatimGeocoder();
  bool _busy = false;
  bool _locating = false;
  late double _lat;
  late double _lng;

  static const _fallbackCenter = LatLng(12.9716, 77.5946);
  bool get _blocked => _busy || _locating;

  @override
  void initState() {
    super.initState();
    final addresses = ref.read(savedAddressesProvider).valueOrNull ?? const [];
    _existing = widget.addressId == null
        ? null
        : addresses.where((a) => a.id == widget.addressId).firstOrNull;
    _label = TextEditingController(text: _existing?.label ?? '');
    _line1 = TextEditingController(text: _existing?.line1 ?? '');
    _city = TextEditingController(text: _existing?.city ?? '');
    _state = TextEditingController(text: _existing?.state ?? '');
    _pincode = TextEditingController(text: _existing?.pincode ?? '');
    final start = _initialMapCenter();
    _lat = start.latitude;
    _lng = start.longitude;
  }

  LatLng _initialMapCenter() {
    if (_existing != null) return LatLng(_existing!.lat, _existing!.lng);
    final location = ref.read(homeLocationProvider).valueOrNull;
    if (location != null && location.hasCoords) {
      return LatLng(location.lat!, location.lng!);
    }
    return _fallbackCenter;
  }

  void _applyResolved({
    required double lat,
    required double lng,
    required String displayName,
    String? city,
    String? state,
    String? pincode,
  }) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _line1.text = displayName;
      if (city != null && city.isNotEmpty) _city.text = city;
      if (state != null && state.isNotEmpty) _state.text = state;
      if (pincode != null && pincode.isNotEmpty) _pincode.text = pincode;
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_blocked) return;
    setState(() => _locating = true);
    try {
      final location = await resolveDeviceLocation();
      if (!mounted) return;
      if (!location.hasCoords) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.locationDenied'.tr())),
        );
        return;
      }
      final result = await _geocoder.reverse(
        lat: location.lat!,
        lng: location.lng!,
      );
      if (!mounted) return;
      _applyResolved(
        lat: location.lat!,
        lng: location.lng!,
        displayName: result.displayName,
        city: result.city,
        state: result.state,
        pincode: result.pincode,
      );
    } catch (error) {
      if (!mounted) return;
      final message =
          error is ApiException ? error.message : 'profile.geocodeFailed'.tr();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickOnMap() async {
    if (_blocked) return;
    final picked = await Navigator.of(context).push<PickedMapAddress>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PickLocationMapScreen(initial: LatLng(_lat, _lng)),
      ),
    );
    if (picked == null || !mounted) return;
    _applyResolved(
      lat: picked.lat,
      lng: picked.lng,
      displayName: picked.displayName,
      city: picked.city,
      state: picked.state,
      pincode: picked.pincode,
    );
  }

  @override
  void dispose() {
    _label.dispose();
    _line1.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final notifier = ref.read(savedAddressesProvider.notifier);
    try {
      if (_existing != null) {
        await notifier.saveUpdated(
          _existing!.copyWith(
            label: _label.text.trim(),
            line1: _line1.text.trim(),
            city: _city.text.trim(),
            state: _state.text.trim(),
            pincode: _pincode.text.trim(),
            lat: _lat,
            lng: _lng,
          ),
        );
      } else {
        await notifier.add(
          SavedAddress(
            id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
            label: _label.text.trim(),
            line1: _line1.text.trim(),
            city: _city.text.trim(),
            state: _state.text.trim(),
            pincode: _pincode.text.trim(),
            lat: _lat,
            lng: _lng,
          ),
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'profile.editAddress'.tr() : 'profile.addAddress'.tr(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _label,
              decoration: InputDecoration(labelText: 'profile.label'.tr()),
              validator: _required,
            ),
            const SizedBox(height: 16),
            AppCard(
              color: AppColors.primarySoft,
              borderColor: AppColors.primary.withValues(alpha: 0.28),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'profile.useCurrentLocationHint'.tr(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressScale(
                    enabled: !_blocked,
                    child: FilledButton.icon(
                      onPressed: _blocked ? null : _useCurrentLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text('profile.useCurrentLocation'.tr()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'profile.orEnterAddress'.tr(),
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _line1,
              decoration: InputDecoration(labelText: 'profile.line1'.tr()),
              validator: _required,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _blocked ? null : _pickOnMap,
              icon: const Icon(Icons.map_outlined),
              label: Text('profile.pickOnMap'.tr()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: InputDecoration(labelText: 'profile.city'.tr()),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _state,
              decoration: InputDecoration(labelText: 'profile.state'.tr()),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pincode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'profile.pincode'.tr()),
              validator: _required,
            ),
            const SizedBox(height: 24),
            PressScale(
              enabled: !_blocked,
              child: FilledButton(
                onPressed: _blocked ? null : _save,
                child: Text('common.save'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }
}
