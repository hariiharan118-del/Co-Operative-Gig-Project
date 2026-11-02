import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'env.dart';

/// Singleton Socket.IO client. Connect after login; listen by event name.
class SocketService {
  SocketService._();

  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  String? _accessToken;
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, int> _bookingRoomRefs = {};
  final Map<String, int> _chatRoomRefs = {};
  String? _supportConversationId;

  bool get isConnected => _socket?.connected ?? false;

  Iterable<String> get _bookingRooms => _bookingRoomRefs.keys;
  Iterable<String> get _chatRooms => _chatRoomRefs.keys;

  void connect({required String accessToken}) {
    if (_socket?.connected == true && _accessToken == accessToken) return;
    // Keep joined booking rooms across access-token refresh. Callers that
    // switch users already disconnect with clearRooms: true first.
    // No artificial delay — tear down and open the new socket immediately.
    disconnect(clearRooms: false);
    _accessToken = accessToken;

    _socket = io.io(
      Env.apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': accessToken})
          .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
          .build(),
    );

    _socket!
      ..onConnect((_) => _rejoinRooms())
      ..onDisconnect((_) {})
      ..onConnectError((_) {});

    for (final entry in _controllers.entries) {
      _bind(entry.key, entry.value);
    }

    if (_socket!.connected) _rejoinRooms();
  }

  void _rejoinRooms() {
    for (final bookingId in _bookingRooms) {
      _socket?.emit('booking:join', bookingId);
      _socket?.emit('chat:join', bookingId);
    }
    for (final bookingId in _chatRooms) {
      _socket?.emit('chat:join', bookingId);
    }
    final conversationId = _supportConversationId;
    if (conversationId != null) {
      _socket?.emit('support:join', conversationId);
    }
  }

  void joinBooking(String bookingId) {
    if (bookingId.isEmpty) return;
    final next = (_bookingRoomRefs[bookingId] ?? 0) + 1;
    _bookingRoomRefs[bookingId] = next;
    if (next == 1) {
      _socket?.emit('booking:join', bookingId);
      _socket?.emit('chat:join', bookingId);
    }
  }

  /// Re-emit join for an already-tracked room (e.g. after token refresh).
  void rejoinBooking(String bookingId) {
    if (bookingId.isEmpty) return;
    if ((_bookingRoomRefs[bookingId] ?? 0) <= 0) {
      joinBooking(bookingId);
      return;
    }
    _socket?.emit('booking:join', bookingId);
    _socket?.emit('chat:join', bookingId);
  }

  void leaveBooking(String bookingId) {
    if (bookingId.isEmpty) return;
    final current = _bookingRoomRefs[bookingId] ?? 0;
    if (current <= 1) {
      _bookingRoomRefs.remove(bookingId);
      _socket?.emit('booking:leave', bookingId);
      _socket?.emit('chat:leave', bookingId);
      return;
    }
    _bookingRoomRefs[bookingId] = current - 1;
  }

  /// Support-conversation room — one active conversation at a time, so no
  /// ref-counting; the server has no matching leave event (Socket.IO drops
  /// the room membership on disconnect). Tracked so a reconnect (e.g. after
  /// a token refresh) rejoins it, same as booking/chat rooms.
  void joinSupport(String conversationId) {
    if (conversationId.isEmpty) return;
    _supportConversationId = conversationId;
    _socket?.emit('support:join', conversationId);
  }

  void joinChat(String bookingId) {
    if (bookingId.isEmpty) return;
    final next = (_chatRoomRefs[bookingId] ?? 0) + 1;
    _chatRoomRefs[bookingId] = next;
    if (next == 1) {
      _socket?.emit('chat:join', bookingId);
    }
  }

  void leaveChat(String bookingId) {
    if (bookingId.isEmpty) return;
    final current = _chatRoomRefs[bookingId] ?? 0;
    if (current <= 1) {
      _chatRoomRefs.remove(bookingId);
      _socket?.emit('chat:leave', bookingId);
      return;
    }
    _chatRoomRefs[bookingId] = current - 1;
  }

  Stream<dynamic> on(String eventName) {
    final existing = _controllers[eventName];
    if (existing != null) return existing.stream;

    final controller = StreamController<dynamic>.broadcast();
    _controllers[eventName] = controller;
    _bind(eventName, controller);
    return controller.stream;
  }

  void _bind(String eventName, StreamController<dynamic> controller) {
    _socket?.on(eventName, (data) {
      if (!controller.isClosed) controller.add(data);
    });
  }

  void emit(String eventName, [dynamic data]) {
    _socket?.emit(eventName, data);
  }

  void disconnect({bool clearRooms = false}) {
    _socket?.dispose();
    _socket = null;
    _accessToken = null;
    if (clearRooms) {
      _bookingRoomRefs.clear();
      _chatRoomRefs.clear();
      _supportConversationId = null;
    }
  }

  Future<void> dispose() async {
    disconnect(clearRooms: true);
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
  }
}
