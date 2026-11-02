import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/socket_service.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/support_repository.dart';
import '../domain/chat_message.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});

bool isDemoSession(AuthState auth) {
  return auth is AuthAuthenticated &&
      auth.session.accessToken.startsWith('demo-');
}

class SupportChatState {
  const SupportChatState({
    this.conversationId,
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.deleting = false,
    this.error,
    this.needsSignIn = false,
  });

  final String? conversationId;
  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final bool deleting;
  final String? error;
  final bool needsSignIn;

  SupportChatState copyWith({
    String? conversationId,
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    bool? deleting,
    String? error,
    bool? needsSignIn,
    bool clearError = false,
  }) {
    return SupportChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      deleting: deleting ?? this.deleting,
      error: clearError ? null : (error ?? this.error),
      needsSignIn: needsSignIn ?? this.needsSignIn,
    );
  }
}

final supportChatProvider =
    NotifierProvider<SupportChatNotifier, SupportChatState>(
  SupportChatNotifier.new,
);

class SupportChatNotifier extends Notifier<SupportChatState> {
  StreamSubscription<dynamic>? _messageSub;
  String? _joinedConversationId;

  @override
  SupportChatState build() {
    ref.onDispose(() => _messageSub?.cancel());
    _messageSub ??=
        SocketService.instance.on('support:message').listen(_onSocketMessage);
    return const SupportChatState();
  }

  SupportRepository get _repo => ref.read(supportRepositoryProvider);

  Future<void> open() async {
    if (isDemoSession(ref.read(authProvider))) {
      state = const SupportChatState(needsSignIn: true);
      return;
    }

    state = state.copyWith(loading: true, clearError: true, needsSignIn: false);
    try {
      final existing = await _repo.list();
      final conversation = existing.isNotEmpty
          ? await _repo.getById(existing.first.id)
          : await _repo.create();
      state = SupportChatState(
        conversationId: conversation.id,
        messages: conversation.messages,
      );
      _joinConversation(conversation.id);
    } catch (error) {
      state = SupportChatState(error: error.toString());
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    if (isDemoSession(ref.read(authProvider))) {
      state = state.copyWith(needsSignIn: true);
      return;
    }

    state = state.copyWith(sending: true, clearError: true);
    try {
      final conversationId = state.conversationId;
      final conversation = conversationId == null || conversationId.isEmpty
          ? await _repo.create(message: trimmed)
          : await _repo.send(conversationId, trimmed);
      state = SupportChatState(
        conversationId: conversation.id,
        messages: conversation.messages,
      );
      _joinConversation(conversation.id);
    } catch (error) {
      state = state.copyWith(sending: false, error: error.toString());
    }
  }

  Future<bool> deleteConversation() async {
    final conversationId = state.conversationId;
    if (conversationId == null || conversationId.isEmpty || state.deleting) {
      return false;
    }

    state = state.copyWith(deleting: true, clearError: true);
    try {
      await _repo.delete(conversationId);
      _joinedConversationId = null;
      state = const SupportChatState();
      return true;
    } catch (error) {
      state = state.copyWith(deleting: false, error: error.toString());
      return false;
    }
  }

  void _joinConversation(String id) {
    if (id.isEmpty || id == _joinedConversationId) return;
    _joinedConversationId = id;
    SocketService.instance.joinSupport(id);
  }

  /// Live delivery for messages that don't originate from this device's own
  /// send() call — an agent taking over, or an AI reply generated after the
  /// request that created it already returned.
  void _onSocketMessage(dynamic raw) {
    final conversationId = state.conversationId;
    if (conversationId == null || conversationId.isEmpty) return;
    final eventConversationId = ChatMessage.conversationIdOf(raw);
    if (eventConversationId != null && eventConversationId != conversationId) {
      return;
    }
    final message = ChatMessage.tryParse(raw);
    if (message == null) return;
    if (state.messages.any((existing) => existing.id == message.id)) return;

    final merged = [...state.messages, message]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    state = state.copyWith(messages: merged, sending: false);
  }
}
