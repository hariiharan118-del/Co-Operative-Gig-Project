import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_error.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/domain/models.dart';
import '../../home/domain/service_category.dart';
import '../data/addresses_repository.dart';
import '../data/bookings_repository.dart';
import '../data/services_repository.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository(ref.watch(apiClientProvider));
});

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return AddressesRepository(ref.watch(apiClientProvider));
});

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository(ref.watch(apiClientProvider));
});

bool isDemoSession(AuthState auth) {
  return auth is AuthAuthenticated &&
      auth.session.accessToken.startsWith('demo-');
}

bool isCustomerSession(AuthState auth) {
  if (auth is! AuthAuthenticated) return false;
  if (isDemoSession(auth)) return true;
  final role = auth.session.user?.roleName ?? '';
  return role.isEmpty || role == 'CUSTOMER';
}

final serviceCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final auth = ref.watch(authProvider);
  if (isDemoSession(auth)) return mockCategories;
  try {
    final items = await ref.watch(servicesRepositoryProvider).list();
    return items.isEmpty ? mockCategories : items;
  } catch (_) {
    return mockCategories;
  }
});

final bookingPaymentProvider =
    FutureProvider.family<PaymentReceipt?, String>((ref, bookingId) async {
  final auth = ref.watch(authProvider);
  if (isDemoSession(auth) || !looksLikeUuid(bookingId)) return null;
  try {
    return await ref.watch(bookingsRepositoryProvider).getPayment(bookingId);
  } catch (_) {
    return null;
  }
});

final myBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final shouldFetch = ref.watch(
    authProvider.select(
      (auth) => auth is AuthAuthenticated && !isDemoSession(auth),
    ),
  );
  if (!shouldFetch) return const [];
  return ref.watch(bookingsRepositoryProvider).list();
});

final bookingDraftProvider =
    NotifierProvider<BookingDraftNotifier, BookingDraft>(
  BookingDraftNotifier.new,
);

class BookingDraftNotifier extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => const BookingDraft();

  void startWith(ServiceCategory category) {
    state = BookingDraft(
      categoryId: category.id,
      categoryName: category.name,
      basePricePaise: category.basePricePaise,
    );
  }

  void setAddress(SavedAddress address) {
    state = state.copyWith(address: address);
  }

  void setTiming(BookingTiming timing, {DateTime? scheduledAt}) {
    state = state.copyWith(
      timing: timing,
      scheduledAt: scheduledAt,
      clearSchedule: timing == BookingTiming.instant,
    );
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void reset() {
    state = const BookingDraft();
  }
}

const _demoAddresses = [
  SavedAddress(
    id: 'addr_home',
    label: 'Home',
    line1: '12 MG Road, Shivajinagar',
    city: 'Bengaluru',
    pincode: '560001',
    lat: 12.9756,
    lng: 77.6050,
  ),
  SavedAddress(
    id: 'addr_office',
    label: 'Office',
    line1: '45 100 Feet Road, Indiranagar',
    city: 'Bengaluru',
    pincode: '560038',
    lat: 12.9784,
    lng: 77.6408,
  ),
];

final savedAddressesProvider =
    AsyncNotifierProvider<SavedAddressesNotifier, List<SavedAddress>>(
  SavedAddressesNotifier.new,
);

class SavedAddressesNotifier extends AsyncNotifier<List<SavedAddress>> {
  @override
  Future<List<SavedAddress>> build() async {
    final auth = ref.watch(authProvider);
    if (isDemoSession(auth)) return _demoAddresses;
    if (!isCustomerSession(auth)) return const [];
    return ref.read(addressesRepositoryProvider).list();
  }

  Future<void> add(SavedAddress address) async {
    final auth = ref.read(authProvider);
    if (!isCustomerSession(auth)) return;
    if (isDemoSession(auth)) {
      final current = state.value ?? const [];
      state = AsyncData([
        ...current,
        address.copyWith(id: 'addr_${DateTime.now().millisecondsSinceEpoch}'),
      ]);
      return;
    }
    final created = await ref.read(addressesRepositoryProvider).create(address);
    state = AsyncData([...(state.value ?? const []), created]);
  }

  Future<void> saveUpdated(SavedAddress address) async {
    final auth = ref.read(authProvider);
    if (!isCustomerSession(auth)) return;
    if (isDemoSession(auth)) {
      state = AsyncData([
        for (final item in state.value ?? const [])
          if (item.id == address.id) address else item,
      ]);
      return;
    }
    final updated = await ref.read(addressesRepositoryProvider).update(address);
    state = AsyncData([
      for (final item in state.value ?? const [])
        if (item.id == updated.id) updated else item,
    ]);
  }

  Future<void> remove(String id) async {
    final auth = ref.read(authProvider);
    if (!isCustomerSession(auth)) return;
    if (isDemoSession(auth)) {
      state = AsyncData([
        for (final item in state.value ?? const [])
          if (item.id != id) item,
      ]);
      return;
    }
    await ref.read(addressesRepositoryProvider).delete(id);
    state = AsyncData([
      for (final item in state.value ?? const [])
        if (item.id != id) item,
    ]);
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final auth = ref.watch(authProvider);
    return _fromAuth(auth);
  }

  Future<void> save({required String name, String? email}) {
    return ref.read(authProvider.notifier).saveCustomerProfile(
          name: name,
          email: email,
        );
  }

  UserProfile _fromAuth(AuthState auth) {
    if (auth is! AuthAuthenticated) {
      return const UserProfile(name: '', phone: '', email: '');
    }
    final user = auth.session.user;
    return UserProfile(
      id: user?.id ?? '',
      name: user?.name?.trim().isNotEmpty == true ? user!.name!.trim() : '',
      phone: formatLoginPhone(user?.phone ?? ''),
      email: user?.email?.trim() ?? '',
    );
  }
}

String formatLoginPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    final local = digits.substring(2);
    return '+91 ${local.substring(0, 5)} ${local.substring(5)}';
  }
  if (digits.length == 10) {
    return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
  }
  return raw;
}
