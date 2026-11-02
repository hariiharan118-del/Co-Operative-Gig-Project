import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/api_error.dart';
import '../domain/past_job.dart';

class HistoryRepository {
  HistoryRepository(this._api);

  final ApiClient _api;

  Future<List<PastJob>> listCompleted() async {
    try {
      final response = await _api.dio.get<dynamic>(
        '/bookings',
        queryParameters: const {'status': 'COMPLETED', 'limit': 100},
      );
      return _unwrapList(response.data)
          .map(PastJob.tryParse)
          .whereType<PastJob>()
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    } on DioException catch (error) {
      throw Exception(describeApiError(error));
    }
  }

  List<dynamic> _unwrapList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['items', 'jobs', 'data', 'bookings']) {
        final value = data[key];
        if (value is List) return value;
      }
    }
    return const [];
  }
}
