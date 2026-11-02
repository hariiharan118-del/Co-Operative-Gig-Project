import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_error.dart';
import '../../../core/socket_service.dart';
import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/data/booking_mapper.dart';
import '../../booking/domain/models.dart';
import '../../booking/providers/booking_providers.dart';

Future<void> showBookingChatOverlay({
  required BuildContext context,
  required String bookingId,
  required String? currentUserId,
  List<ChatMessage> initialMessages = const [],
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'common.chat'.tr(),
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _BookingChatOverlay(
        bookingId: bookingId,
        currentUserId: currentUserId,
        initialMessages: initialMessages,
      );
    },
  );
}

class _BookingChatOverlay extends ConsumerStatefulWidget {
  const _BookingChatOverlay({
    required this.bookingId,
    required this.currentUserId,
    required this.initialMessages,
  });

  final String bookingId;
  final String? currentUserId;
  final List<ChatMessage> initialMessages;

  @override
  ConsumerState<_BookingChatOverlay> createState() => _BookingChatOverlayState();
}

class _BookingChatOverlayState extends ConsumerState<_BookingChatOverlay> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late List<ChatMessage> _messages;
  StreamSubscription<dynamic>? _sub;
  bool _sending = false;

  bool get _useApi {
    final auth = ref.read(authProvider);
    return looksLikeUuid(widget.bookingId) && !isDemoSession(auth);
  }

  @override
  void initState() {
    super.initState();
    _messages = [...widget.initialMessages];
    SocketService.instance.joinChat(widget.bookingId);
    _sub = SocketService.instance.on('chat:message').listen(_onSocketMessage);
    _scrollToEnd();
    Future.microtask(_loadHistory);
  }

  Future<void> _loadHistory() async {
    if (!_useApi) return;
    try {
      final items = await ref.read(bookingsRepositoryProvider).listChatMessages(
            widget.bookingId,
            currentUserId: widget.currentUserId,
          );
      if (!mounted) return;
      setState(() => _messages = items);
      _scrollToEnd();
    } catch (_) {}
  }

  void _onSocketMessage(dynamic raw) {
    final incoming = chatMessageFromSocket(
      raw,
      currentUserId: widget.currentUserId,
    );
    if (incoming.body.isEmpty) return;
    final json = asJsonMap(raw);
    if (json != null &&
        asString(json['bookingId']) != null &&
        asString(json['bookingId']) != widget.bookingId) {
      return;
    }
    _append(incoming);
  }

  void _append(ChatMessage incoming) {
    setState(() {
      if (incoming.id.isNotEmpty &&
          _messages.any((item) => item.id == incoming.id)) {
        return;
      }
      if (incoming.fromUser) {
        _messages.removeWhere(
          (item) =>
              item.id.startsWith('local-') &&
              item.body == incoming.body &&
              item.fromUser,
        );
      }
      _messages = [..._messages, incoming];
    });
    _scrollToEnd();
  }

  @override
  void dispose() {
    _sub?.cancel();
    SocketService.instance.leaveChat(widget.bookingId);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();

    if (!_useApi) {
      _append(
        ChatMessage(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          body: text,
          fromUser: true,
          sentAt: DateTime.now(),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final sent = await ref.read(bookingsRepositoryProvider).sendChatMessage(
            widget.bookingId,
            text,
            currentUserId: widget.currentUserId,
          );
      if (!mounted) return;
      _append(sent);
    } catch (error) {
      if (!mounted) return;
      _controller.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final wide = size.width >= 640;
    final width = wide ? 360.0 : size.width - 24;
    final height = (size.height * 0.48).clamp(320.0, 420.0);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: wide ? Alignment.bottomRight : Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, wide ? 24 : 16),
          child: Material(
            color: AppColors.card,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: SizedBox(
              width: width,
              height: height,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'tracking.jobChat'.tr(),
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: InvitationEmpty(
                              emoji: '💬',
                              message: 'tracking.chatEmpty'.tr(),
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return Align(
                                alignment: message.fromUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  constraints: const BoxConstraints(maxWidth: 260),
                                  decoration: BoxDecoration(
                                    color: message.fromUser
                                        ? AppColors.primary
                                        : AppColors.background,
                                    border: message.fromUser
                                        ? null
                                        : Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    message.body,
                                    style: TextStyle(
                                      color: message.fromUser
                                          ? Colors.white
                                          : AppColors.navy,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !_sending,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: 'support.inputHint'.tr(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          icon: const Icon(Icons.send, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
