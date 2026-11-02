import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/razorpay_checkout.dart';
import '../../../core/socket_service.dart';
import '../../job/domain/active_job.dart';
import '../../job/domain/booking_chat_message.dart';
import '../domain/nearby_job.dart';

class JobsRepository {
  JobsRepository(this._api);

  final ApiClient _api;

  Future<List<NearbyJob>> listAvailable() async {
    final response = await _api.dio.get<dynamic>('/workers/jobs/available');
    return _unwrapList(response.data)
        .map(NearbyJob.tryParse)
        .whereType<NearbyJob>()
        .toList();
  }

  Future<ActiveJob?> findActive() async {
    final response = await _api.dio.get<dynamic>(
      '/bookings',
      queryParameters: const {'limit': 50},
    );
    for (final raw in _unwrapList(response.data)) {
      final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
      if (map == null || !isOpenBookingStatus(map['status'])) continue;
      return activeJobFromBooking(map);
    }
    return null;
  }

  Future<ActiveJob?> getBooking(String bookingId) async {
    final response = await _api.dio.get<dynamic>('/bookings/$bookingId');
    return activeJobFromBooking(response.data);
  }

  Future<List<BookingChatMessage>> listChatMessages(
    String bookingId, {
    String? currentUserId,
  }) async {
    try {
      final response = await _api.dio.get<dynamic>(
        '/bookings/$bookingId/chat/messages',
      );
      return bookingChatMessagesFromResponse(
        response.data,
        currentUserId: currentUserId,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<BookingChatMessage> sendChatMessage(
    String bookingId,
    String content, {
    String? currentUserId,
  }) async {
    try {
      final response = await _api.dio.post<dynamic>(
        '/bookings/$bookingId/chat/messages',
        data: {'content': content},
      );
      final message = bookingChatMessageFromJson(
        response.data,
        currentUserId: currentUserId,
      );
      if (message == null) {
        throw StateError('Chat send response was empty');
      }
      return message;
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
      SocketService.instance.emit('chat:message', {
        'bookingId': bookingId,
        'content': content,
      });
      return BookingChatMessage(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        body: content,
        fromUser: true,
        sentAt: DateTime.now(),
        bookingId: bookingId,
      );
    }
  }

  Future<NearbyJob> accept(String bookingId) async {
    try {
      final response = await _api.dio.post<dynamic>(
        '/workers/jobs/$bookingId/accept',
      );
      final job = NearbyJob.tryParse(response.data);
      if (job != null) return job;
      final id = bookingIdFromPayload(response.data) ?? bookingId;
      return NearbyJob(
        id: id,
        serviceType: 'Job',
        distanceKm: 0,
        estimatedPayPaise: 0,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        throw const JobTakenException();
      }
      rethrow;
    }
  }

  Future<CallConnectResult> initiateCall(String bookingId) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/bookings/$bookingId/call/customer',
    );
    return CallConnectResult.fromJson(response.data ?? const {});
  }

  Future<PaymentOrder> createPaymentOrder(String bookingId) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/bookings/$bookingId/payment/create-order',
    );
    return PaymentOrder.fromJson(response.data ?? const {});
  }

  Future<ActiveJob?> markCashReceived(String bookingId) async {
    final response = await _api.dio.post<dynamic>(
      '/bookings/$bookingId/payment/mark-cash-received',
    );
    return activeJobFromBooking(response.data);
  }

  Future<void> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await _api.dio.post<Map<String, dynamic>>(
      '/bookings/$bookingId/payment/verify',
      data: {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );
  }

  Future<ActiveJob?> updateStatus(
    String bookingId,
    JobLifecycleStatus next,
  ) async {
    final response = await _api.dio.patch<dynamic>(
      '/bookings/$bookingId/status',
      data: {'status': next.apiName},
    );
    return activeJobFromBooking(response.data);
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

class CallConnectResult {
  const CallConnectResult({required this.masked, this.phoneNumber});

  final bool masked;
  final String? phoneNumber;

  factory CallConnectResult.fromJson(Map<String, dynamic> json) {
    final raw = json['phoneNumber']?.toString().trim();
    final phone = (raw == null || raw.isEmpty) ? null : raw;
    return CallConnectResult(
      masked: json['masked'] as bool? ?? phone == null,
      phoneNumber: phone,
    );
  }
}
