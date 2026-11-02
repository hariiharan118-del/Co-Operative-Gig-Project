import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/socket_service.dart';
import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../domain/booking_chat_message.dart';

Future<void> showBookingChatOverlay({
  required BuildContext context,
  required String bookingId,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'common.chat'.tr(),
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _BookingChatOverlay(bookingId: bookingId);
    },
  );
}

class _BookingChatOverlay extends ConsumerStatefulWidget {
  const _BookingChatOverlay({required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<_BookingChatOverlay> createState() => _BookingChatOverlayState();
}

class _BookingChatOverlayState extends ConsumerState<_BookingChatOverlay> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <BookingChatMessage>[];
  StreamSubscription<dynamic>? _sub;
  bool _sending = false;

  String? get _currentUserId {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) return auth.session.user?.id;
    return null;
  }

  bool get _live {
    final auth = ref.read(authProvider);
    final demo = auth is AuthAuthenticated &&
        auth.session.accessToken.startsWith('demo-');
    return looksLikeUuid(widget.bookingId) && !demo;
  }

  @override
  void initState() {
    super.initState();
    SocketService.instance.joinChat(widget.bookingId);
    _sub = SocketService.instance.on('chat:message').listen(_onSocketMessage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadHistory());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    SocketService.instance.leaveChat(widget.bookingId);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!_live) return;
    try {
      final items = await ref.read(jobsRepositoryProvider).listChatMessages(
            widget.bookingId,
            currentUserId: _currentUserId,
          );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(items);
      });
      _scrollToEnd();
    } catch (_) {}
  }

  void _onSocketMessage(dynamic raw) {
    final incoming = bookingChatMessageFromJson(
      raw,
      currentUserId: _currentUserId,
    );
    if (incoming == null) return;
    if (incoming.bookingId != null && incoming.bookingId != widget.bookingId) {
      return;
    }
    _upsert(incoming);
  }

  void _upsert(BookingChatMessage incoming) {
    if (incoming.body.isEmpty) return;
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
      _messages.add(incoming);
    });
    _scrollToEnd();
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

    if (!_live) {
      _upsert(
        BookingChatMessage(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          body: text,
          fromUser: true,
          sentAt: DateTime.now(),
          bookingId: widget.bookingId,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final sent = await ref.read(jobsRepositoryProvider).sendChatMessage(
            widget.bookingId,
            text,
            currentUserId: _currentUserId,
          );
      if (!mounted) return;
      _upsert(sent);
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
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.line),
            ),
            child: SizedBox(
              width: width,
              height: height,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'job.chatTitle'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        CircleIconButton(
                          icon: Icons.close,
                          size: 32,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: InvitationEmpty(
                              emoji: '💬',
                              message: 'job.chatEmpty'.tr(),
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
                                  constraints:
                                      const BoxConstraints(maxWidth: 240),
                                  decoration: BoxDecoration(
                                    color: message.fromUser
                                        ? AppColors.accent
                                        : AppColors.canvas,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    message.body,
                                    style: TextStyle(
                                      color: message.fromUser
                                          ? Colors.white
                                          : AppColors.ink,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            enabled: !_sending,
                            onSubmitted: (_) => unawaited(_send()),
                            decoration: InputDecoration(
                              hintText: 'support.inputHint'.tr(),
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.canvas,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleIconButton(
                          icon: Icons.send_rounded,
                          background: AppColors.accent,
                          foreground: Colors.white,
                          size: 40,
                          onPressed: _sending ? null : () => unawaited(_send()),
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
