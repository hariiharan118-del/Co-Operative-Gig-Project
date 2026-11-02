import 'package:dio/dio.dart';

import '../../../core/api_error.dart';

const nominatimUserAgent =
    'KRIYANTA-Customer/1.0 (coop-gig address picker)';

class ReverseGeocodeResult {
  const ReverseGeocodeResult({
    required this.displayName,
    this.city,
    this.state,
    this.pincode,
  });

  final String displayName;
  final String? city;
  final String? state;
  final String? pincode;
}

/// Reverse-geocodes a single coordinate pair. Call only on confirm, not on pan.
class NominatimGeocoder {
  NominatimGeocoder({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://nominatim.openstreetmap.org',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent': nominatimUserAgent,
                  'Accept': 'application/json',
                  'Accept-Language': 'en',
                },
              ),
            );

  final Dio _dio;

  Future<ReverseGeocodeResult> reverse({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'jsonv2',
          'addressdetails': 1,
        },
      );
      final data = response.data ?? const {};
      final address = data['address'];
      final parts = address is Map
          ? address.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{};

      final display = (data['display_name'] as String?)?.trim();
      if (display == null || display.isEmpty) {
        throw ApiException('Could not look up that location.');
      }

      return ReverseGeocodeResult(
        displayName: display,
        city: _first(parts, const [
          'city',
          'town',
          'village',
          'municipality',
          'suburb',
        ]),
        state: _first(parts, const ['state', 'region']),
        pincode: _first(parts, const ['postcode']),
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throwFromDio(error, 'Could not look up that location.');
    }
  }

  String? _first(Map<String, dynamic> parts, List<String> keys) {
    for (final key in keys) {
      final value = parts[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
