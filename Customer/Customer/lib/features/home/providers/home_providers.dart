import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device_location.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/providers/booking_providers.dart';
import '../data/workers_repository.dart';
import '../domain/nearby_provider.dart';

final workersRepositoryProvider = Provider<WorkersRepository>((ref) {
  return WorkersRepository(ref.watch(apiClientProvider));
});

final homeLocationProvider = FutureProvider<DeviceLocation>((ref) {
  return resolveDeviceLocation();
});

final locationHintDismissedProvider = StateProvider<bool>((ref) => false);

final nearbyProvidersProvider = FutureProvider<List<NearbyProvider>>((ref) async {
  final auth = ref.watch(authProvider);
  if (isDemoSession(auth)) {
    final location = await ref.watch(homeLocationProvider.future);
    return mockNearbyProviders(includeDistance: location.hasCoords);
  }
  if (!isCustomerSession(auth)) return const [];
  try {
    final location = await ref.watch(homeLocationProvider.future);
    return await ref.watch(workersRepositoryProvider).listApproved(
          lat: location.lat,
          lng: location.lng,
        );
  } catch (_) {
    return const [];
  }
});
