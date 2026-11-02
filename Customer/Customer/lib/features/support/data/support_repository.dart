import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/api_error.dart';
import '../../booking/domain/models.dart';

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
      final items = _asList(response.data);
      return [
        for (final item in items)
          if (item is Map) _conversationFromJson(Map<String, dynamic>.from(item)),
      ];
    } on DioException catch (error) {
      throwFromDio(error, 'Could not load support chats');
    }
  }

  Future<SupportConversation> getById(String id) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/support/conversations/$id',
      );
      return _conversationFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throwFromDio(error, 'Could not load support chat');
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
      throwFromDio(error, 'Could not start support chat');
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
      throwFromDio(error, 'Could not send message');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.dio.delete<void>('/support/conversations/$id');
    } on DioException catch (error) {
      throwFromDio(error, 'Could not delete support chat');
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
        if (item is! Map) continue;
        final row = Map<String, dynamic>.from(item);
        final sender = '${row['sender'] ?? ''}'.toUpperCase();
        messages.add(
          ChatMessage(
            id: '${row['id'] ?? ''}',
            body: '${row['content'] ?? row['body'] ?? ''}',
            fromUser: sender == 'USER',
            sentAt: DateTime.tryParse('${row['createdAt'] ?? ''}') ?? DateTime.now(),
          ),
        );
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
