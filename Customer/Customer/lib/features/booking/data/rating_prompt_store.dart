import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers bookings whose live rating prompt was already shown (rated or dismissed).
class RatingPromptStore {
  RatingPromptStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'rating_prompted_booking_ids';

  final FlutterSecureStorage _storage;
  Set<String>? _cache;

  Future<Set<String>> _ids() async {
    if (_cache != null) return _cache!;
    final raw = await _storage.read(key: _key);
    _cache = {
      if (raw != null)
        for (final id in raw.split(','))
          if (id.trim().isNotEmpty) id.trim(),
    };
    return _cache!;
  }

  Future<bool> wasPrompted(String bookingId) async {
    return (await _ids()).contains(bookingId);
  }

  Future<void> markPrompted(String bookingId) async {
    if (bookingId.isEmpty) return;
    final ids = await _ids();
    if (!ids.add(bookingId)) return;
    _cache = ids;
    await _storage.write(key: _key, value: ids.join(','));
  }
}

final ratingPromptStoreProvider = Provider<RatingPromptStore>((ref) {
  return RatingPromptStore();
});
