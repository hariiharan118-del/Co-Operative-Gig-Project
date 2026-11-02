import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../auth/domain/auth_state.dart';

class ServiceCategoryOption {
  const ServiceCategoryOption({required this.id, required this.name});

  final String id;
  final String name;
}

class ServicesCatalog {
  ServicesCatalog(this._api);

  final ApiClient _api;

  Future<List<ServiceCategoryOption>> list() async {
    try {
      final response = await _api.dio.get<dynamic>('/services');
      dynamic data = response.data;
      if (data is Map) {
        data = data['data'] ?? data['items'] ?? data['categories'];
      }
      if (data is! List) return const [];
      final out = <ServiceCategoryOption>[];
      final seen = <String>{};
      void add(Map<String, dynamic> map) {
        final id = '${map['id'] ?? ''}';
        if (id.isNotEmpty && seen.add(id)) {
          out.add(
            ServiceCategoryOption(
              id: id,
              name: '${map['name'] ?? 'Service'}',
            ),
          );
        }
        final children = map['children'];
        if (children is List) {
          for (final child in children) {
            final childMap = authJsonMap(child);
            if (childMap != null) add(childMap);
          }
        }
      }

      for (final item in data) {
        final map = authJsonMap(item);
        if (map != null) add(map);
      }
      return out;
    } on DioException {
      return const [];
    }
  }
}
