import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/api_error.dart';
import '../../booking/data/booking_mapper.dart';
import '../../providers/domain/provider_models.dart';
import '../domain/nearby_provider.dart';
import '../domain/service_category.dart';

class WorkersRepository {
  WorkersRepository(this._api);

  final ApiClient _api;

  Future<List<NearbyProvider>> listApproved({double? lat, double? lng}) async {
    try {
      final response = await _api.dio.get<dynamic>(
        '/workers',
        queryParameters: lat != null && lng != null
            ? {'lat': lat, 'lng': lng}
            : null,
      );
      return nearbyProvidersFromResponse(response.data);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 404 || status == 403) return const [];
      throwFromDio(error, 'Could not load providers');
    }
  }
}

List<NearbyProvider> nearbyProvidersFromResponse(dynamic raw) {
  var value = raw;
  final map = asJsonMap(raw);
  if (map != null) {
    value = map['items'] ?? map['workers'] ?? raw;
  }
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (asJsonMap(item) != null) nearbyProviderFromJson(asJsonMap(item)!),
  ];
}

NearbyProvider nearbyProviderFromJson(Map<String, dynamic> json) {
  final rating = asDouble(json['ratingAverage'] ?? json['rating']);
  final paiseRaw = json['startingPricePaise'];
  final category = asJsonMap(json['category']);
  final badgesRaw = (json['badges'] as List?) ?? (json['badgeLabels'] as List?);
  final badges = badgesRaw != null
      ? badgesRaw
          .map((b) => b is Map ? b['label']?.toString() ?? '' : b.toString())
          .where((s) => s.isNotEmpty)
          .toList()
      : <String>[];

  final isProbation = json['isProbation'] == true ||
      json['verificationStatus'] == 'COMMUNITY_VERIFIED_PROBATION' ||
      badges.any((b) => b.toLowerCase().contains('probation'));

  final isTrusted = json['isTrusted'] == true ||
      json['verificationStatus'] == 'TRUSTED_WORKER' ||
      badges.any((b) => b.toLowerCase().contains('trusted'));

  final isCertificateVerified = json['isCertificateVerified'] == true ||
      badges.any((b) => b.toLowerCase().contains('certificate'));

  return NearbyProvider(
    id: asString(json['id'] ?? json['userId']) ?? '',
    name: asString(json['name']) ?? 'Worker',
    photoUrl: asString(json['photoUrl'] ?? json['photo'] ?? json['avatarUrl']),
    specialty: asString(
      json['specialty'] ?? json['skill'] ?? category?['name'],
    ),
    categoryId: asString(json['categoryId'] ?? category?['id']),
    categorySlug: asString(json['categorySlug'] ?? category?['slug']),
    ratingAverage: rating > 0 ? rating : null,
    startingPricePaise: paiseRaw is int && paiseRaw > 0
        ? paiseRaw
        : _paiseOrNull(
            json['startingPrice'] ??
                json['basePricing'] ??
                category?['basePricing'],
          ),
    tags: _stringList(json['tags'] ?? json['skills']),
    locationLabel: _locationLabel(json),
    benefit: asString(json['benefit'] ?? json['perk']),
    verified: json['verified'] == false || json['approved'] == false
        ? false
        : true,
    badges: badges,
    isProbation: isProbation,
    isTrusted: isTrusted,
    isCertificateVerified: isCertificateVerified,
    verificationStatus: asString(json['verificationStatus']),
  );
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (asString(item) != null) asString(item)!,
  ];
}

String? _locationLabel(Map<String, dynamic> json) {
  final labeled = asString(
    json['locationLabel'] ?? json['area'] ?? json['locality'] ?? json['city'],
  );
  final km = asDouble(json['distanceKm'] ?? json['distance']);
  if (labeled != null && km > 0) {
    return '$labeled · ${_formatKm(km)}';
  }
  if (labeled != null) return labeled;
  if (km > 0) return _formatKm(km);
  return null;
}

String _formatKm(double km) {
  final value = km >= 10 ? km.round().toString() : km.toStringAsFixed(1);
  return '$value km away';
}

int? _paiseOrNull(dynamic raw) {
  if (raw == null) return null;
  final paise = rupeesToPaise(raw);
  return paise > 0 ? paise : null;
}

List<NearbyProvider> mockNearbyProviders({bool includeDistance = true}) {
  final items = [
    NearbyProvider(
      id: mockProviders[0].id,
      name: mockProviders[0].name,
      specialty: mockProviders[0].specialty,
      categoryId: _categoryIdFor(mockProviders[0]),
      categorySlug: 'electrician',
      ratingAverage: 4.8,
      startingPricePaise: _priceFor(mockProviders[0]),
      tags: const ['Wiring', 'Fixtures', 'Panel work'],
      locationLabel: includeDistance ? 'Indiranagar · 1.2 km away' : 'Indiranagar',
      benefit: 'Same-day visits',
    ),
    NearbyProvider(
      id: mockProviders[1].id,
      name: mockProviders[1].name,
      specialty: mockProviders[1].specialty,
      categoryId: _categoryIdFor(mockProviders[1]),
      categorySlug: 'electrician',
      ratingAverage: 4.9,
      startingPricePaise: _priceFor(mockProviders[1]),
      tags: const ['Commercial wiring', 'Troubleshooting'],
      locationLabel: includeDistance ? 'Koramangala · 2.1 km away' : 'Koramangala',
      benefit: 'Co-op member',
    ),
    NearbyProvider(
      id: mockProviders[2].id,
      name: mockProviders[2].name,
      specialty: mockProviders[2].specialty,
      categoryId: _categoryIdFor(mockProviders[2]),
      categorySlug: 'ac_repair',
      ratingAverage: 4.6,
      startingPricePaise: _priceFor(mockProviders[2]),
      tags: const ['AC repair', 'Gas charging'],
      locationLabel: includeDistance ? 'Whitefield · 4.8 km away' : 'Whitefield',
      benefit: 'Licensed technician',
    ),
  ];
  if (includeDistance) return items;
  final sorted = [...items]
    ..sort((a, b) => (b.ratingAverage ?? 0).compareTo(a.ratingAverage ?? 0));
  return sorted;
}

String _categoryIdFor(MarketplaceProvider item) {
  final key = '${item.specialty} ${item.category}'.toLowerCase();
  for (final category in mockCategories) {
    if (key.contains(category.name.toLowerCase().split(' ').first)) {
      return category.id;
    }
  }
  if (key.contains('electric')) return 'electrician';
  if (key.contains('hvac') || key.contains('ac')) return 'ac_repair';
  return mockCategories.first.id;
}

int _priceFor(MarketplaceProvider item) {
  final id = _categoryIdFor(item);
  for (final category in mockCategories) {
    if (category.id == id) return category.basePricePaise;
  }
  return mockCategories.first.basePricePaise;
}
