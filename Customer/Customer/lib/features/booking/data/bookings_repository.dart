import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/api_error.dart';
import '../../../core/socket_service.dart';
import '../../tracking/data/tracking_ping.dart';
import '../domain/models.dart';
import 'booking_mapper.dart';

class BookingsRepository {
  BookingsRepository(this._api);

  final ApiClient _api;

  Future<Booking> create({
    required String serviceCategoryId,
    required String addressId,
    DateTime? scheduledAt,
    bool isEmergency = false,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/bookings',
        data: {
          'serviceCategoryId': serviceCategoryId,
          'addressId': addressId,
          if (scheduledAt != null)
            'scheduledAt': scheduledAt.toUtc().copyWith(microsecond: 0).toIso8601String(),
          'isEmergency': isEmergency,
        },
      );
      return bookingFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throwFromDio(error, 'Could not create booking');
    }
  }

  Future<List<Booking>> list() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/bookings');
      final items = response.data?['items'];
      if (items is! List) return const [];
      return [
        for (final item in items)
          if (asJsonMap(item) != null) bookingFromJson(asJsonMap(item)!),
      ];
    } on DioException catch (error) {
      throwFromDio(error, 'Could not load bookings');
    }
  }

  Future<Booking> get(String id, {String? currentUserId}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/bookings/$id');
      return bookingFromJson(response.data ?? const {}, currentUserId: currentUserId);
    } on DioException catch (error) {
      throwFromDio(error, 'Could not load booking');
    }
  }

  Future<TrackingPing?> getTracking(String id) async {
    try {
      final response = await _api.dio.get<dynamic>('/bookings/$id/tracking');
      return TrackingPing.tryParse(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throwFromDio(error, 'Could not load tracking');
    }
  }

  Future<Booking> cancel(String id, {String? reason}) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/bookings/$id/cancel',
        data: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return bookingFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throwFromDio(error, 'Could not cancel booking');
    }
  }

  Future<PaymentOrder> createPaymentOrder(String bookingId) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/bookings/$bookingId/payment/create-order',
      );
      return paymentOrderFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throwFromDio(error, 'Could not start payment');
    }
  }

  Future<PaymentReceipt> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/bookings/$bookingId/payment/verify',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      return paymentReceiptFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throwFromDio(error, 'Could not verify payment');
    }
  }

  Future<PaymentReceipt> getPayment(String bookingId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/bookings/$bookingId/payment',
      );
      return paymentReceiptFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throwFromDio(error, 'Could not load receipt');
    }
  }

  Future<CallInitiateResult> initiateCall(String bookingId) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/bookings/$bookingId/call/worker',
      );
      return callInitiateResultFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throwFromDio(error, 'Could not start call');
    }
  }

  Future<List<ChatMessage>> listChatMessages(
    String bookingId, {
    String? currentUserId,
  }) async {
    try {
      final response = await _api.dio.get<dynamic>(
        '/bookings/$bookingId/chat/messages',
      );
      return chatMessagesFromResponse(response.data, currentUserId: currentUserId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const [];
      throwFromDio(error, 'Could not load chat');
    }
  }

  Future<ChatMessage> sendChatMessage(
    String bookingId,
    String content, {
    String? currentUserId,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/bookings/$bookingId/chat/messages',
        data: {'content': content},
      );
      return chatMessageFromSocket(
        response.data,
        currentUserId: currentUserId,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        SocketService.instance.emit('chat:message', {
          'bookingId': bookingId,
          'content': content,
        });
        return ChatMessage(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          body: content,
          fromUser: true,
          sentAt: DateTime.now(),
        );
      }
      throwFromDio(error, 'Could not send message');
    }
  }

  Future<void> submitRating(
    String bookingId, {
    required int rating,
    String? feedback,
  }) async {
    try {
      await _api.dio.post<Map<String, dynamic>>(
        '/bookings/$bookingId/rating',
        data: {
          'rating': rating,
          if (feedback != null && feedback.trim().isNotEmpty)
            'feedback': feedback.trim(),
        },
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) return;
      throwFromDio(error, 'Could not submit rating');
    }
  }
}
