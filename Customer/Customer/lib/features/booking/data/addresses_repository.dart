import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/api_error.dart';
import '../domain/models.dart';
import 'booking_mapper.dart';

class AddressesRepository {
  AddressesRepository(this._api);

  final ApiClient _api;

  Future<List<SavedAddress>> list() async {
    try {
      final response = await _api.dio.get<dynamic>('/users/customer/addresses');
      final data = response.data;
      if (data is! List) return const [];
      return [
        for (final item in data)
          if (asJsonMap(item) != null) addressFromJson(asJsonMap(item)!),
      ];
    } on DioException catch (error) {
      throwFromDio(error, 'Could not load addresses');
    }
  }

  Future<SavedAddress> create(SavedAddress address) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/users/customer/addresses',
        data: _body(address),
      );
      return addressFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throwFromDio(error, 'Could not save address');
    }
  }

  Future<SavedAddress> update(SavedAddress address) async {
    try {
      final response = await _api.dio.put<Map<String, dynamic>>(
        '/users/customer/addresses/${address.id}',
        data: _body(address),
      );
      return addressFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throwFromDio(error, 'Could not update address');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.dio.delete('/users/customer/addresses/$id');
    } on DioException catch (error) {
      throwFromDio(error, 'Could not delete address');
    }
  }

  Map<String, dynamic> _body(SavedAddress address) {
    return {
      'label': address.label,
      'line1': address.line1,
      'city': address.city,
      'state': address.state,
      'pincode': address.pincode,
      'lat': address.lat,
      'lng': address.lng,
    };
  }
}
