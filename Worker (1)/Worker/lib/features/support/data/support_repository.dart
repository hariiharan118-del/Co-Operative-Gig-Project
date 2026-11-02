import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/api_error.dart';
import '../domain/chat_message.dart';

class SupportConversation {
  const SupportConversation({
    required this.id,
    required this.status,
    required this.messages,
  });

  final String id;
  final String status;
  final List<ChatMessage> messages;
}

class SupportRepository {
  SupportRepository(this._api);

  final ApiClient _api;

  static const _timeout = Duration(seconds: 60);

  Future<List<SupportConversation>> list() async {
    try {
      final response = await _api.dio.get<dynamic>('/support/conversations');
      return [
        for (final item in _asList(response.data))
          if (item is Map) _conversationFromJson(Map<String, dynamic>.from(item)),
      ];
    } on DioException catch (error) {
      throw Exception(describeApiError(error));
    }
  }

  Future<SupportConversation> getById(String id) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/support/conversations/$id',
      );
      return _conversationFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw Exception(describeApiError(error));
    }
  }

  Future<SupportConversation> create({String? message}) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/support/conversations',
        data: {
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        },
        options: Options(receiveTimeout: _timeout, sendTimeout: _timeout),
      );
      return _conversationFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw Exception(describeApiError(error));
    }
  }

  Future<SupportConversation> send(String conversationId, String content) async {
    try {
      await _api.dio.post<Map<String, dynamic>>(
        '/support/conversations/$conversationId/messages',
        data: {'content': content.trim()},
        options: Options(receiveTimeout: _timeout, sendTimeout: _timeout),
      );
      return getById(conversationId);
    } on DioException catch (error) {
      throw Exception(describeApiError(error));
    }
  }

  Future<void> delete(String conversationId) async {
    try {
      await _api.dio.delete<void>(
        '/support/conversations/$conversationId',
        options: Options(receiveTimeout: _timeout, sendTimeout: _timeout),
      );
    } on DioException catch (error) {
      throw Exception(describeApiError(error));
    }
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final items = data['items'] ?? data['conversations'];
      if (items is List) return items;
    }
    return const [];
  }

  SupportConversation _conversationFromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final messages = <ChatMessage>[];
    if (rawMessages is List) {
      for (final item in rawMessages) {
        final message = ChatMessage.tryParse(item);
        if (message != null) messages.add(message);
      }
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    }
    return SupportConversation(
      id: '${json['id'] ?? ''}',
      status: '${json['status'] ?? ''}',
      messages: messages,
    );
  }
}
