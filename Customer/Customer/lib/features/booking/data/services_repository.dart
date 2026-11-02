import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/api_error.dart';
import '../../home/domain/service_category.dart';
import 'booking_mapper.dart';

class ServicesRepository {
  ServicesRepository(this._api);

  final ApiClient _api;

  Future<List<ServiceCategory>> list() async {
    try {
      final response = await _api.dio.get<dynamic>('/services');
      final data = response.data;
      if (data is! List) return const [];
      return [
        for (final item in data)
          if (asJsonMap(item) != null) _categoryFrom(asJsonMap(item)!),
      ];
    } on DioException catch (error) {
      throwFromDio(error, 'Could not load services');
    }
  }

  ServiceCategory _categoryFrom(Map<String, dynamic> json) {
    final slug =
        asString(json['slug']) ?? _slugFromName(asString(json['name']) ?? '');
    return ServiceCategory(
      id: asString(json['id']) ?? '',
      name: asString(json['name']) ?? 'Service',
      slug: slug,
      iconName: _iconForSlug(slug),
      basePricePaise: rupeesToPaise(json['basePricing']),
    );
  }

  String _slugFromName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  String _iconForSlug(String slug) {
    return switch (slug) {
      'electrician' => 'electrical_services',
      'plumber' => 'plumbing',
      'carpenter' => 'handyman',
      'painter' => 'format_paint',
      'cleaner' || 'domestic-help' => 'cleaning_services',
      'technician' => 'kitchen',
      'gardener' => 'yard',
      'driver' => 'directions_car',
      'caregiver' => 'favorite',
      _ => 'home_repair_service',
    };
  }
}
