import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/domain/models.dart';
import '../../booking/providers/booking_providers.dart';
import '../data/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});

class SupportChatState {
  const SupportChatState({
    this.conversationId,
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.deleting = false,
    this.error,
  });

  final String? conversationId;
  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final bool deleting;
  final String? error;

  SupportChatState copyWith({
    String? conversationId,
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    bool? deleting,
    String? error,
    bool clearError = false,
  }) {
    return SupportChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      deleting: deleting ?? this.deleting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final supportChatProvider =
    NotifierProvider<SupportChatNotifier, SupportChatState>(
  SupportChatNotifier.new,
);

class SupportChatNotifier extends Notifier<SupportChatState> {
  @override
  SupportChatState build() => const SupportChatState();

  SupportRepository get _repo => ref.read(supportRepositoryProvider);

  Future<void> open() async {
    if (isDemoSession(ref.read(authProvider))) {
      state = const SupportChatState(
        error: 'Sign in with a real account to chat with support.',
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final existing = await _repo.list();
      final conversation = existing.isNotEmpty
          ? await _repo.getById(existing.first.id)
          : await _repo.create();
      state = SupportChatState(
        conversationId: conversation.id,
        messages: conversation.messages,
      );
    } catch (error) {
      state = SupportChatState(error: error.toString());
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    if (isDemoSession(ref.read(authProvider))) {
      state = state.copyWith(error: 'Sign in with a real account to chat with support.');
      return;
    }

    state = state.copyWith(sending: true, clearError: true);
    try {
      var conversationId = state.conversationId;
      SupportConversation conversation;
      if (conversationId == null || conversationId.isEmpty) {
        conversation = await _repo.create(message: trimmed);
      } else {
        conversation = await _repo.send(conversationId, trimmed);
      }
      state = SupportChatState(
        conversationId: conversation.id,
        messages: conversation.messages,
      );
    } catch (error) {
      state = state.copyWith(sending: false, error: error.toString());
    }
  }

  Future<bool> delete() async {
    final conversationId = state.conversationId;
    if (conversationId == null || conversationId.isEmpty || state.deleting) {
      return false;
    }

    state = state.copyWith(deleting: true, clearError: true);
    try {
      await _repo.delete(conversationId);
      state = const SupportChatState();
      return true;
    } catch (error) {
      state = state.copyWith(deleting: false, error: error.toString());
      return false;
    }
  }
}

Future<void> showSupportChatOverlay(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'support.title'.tr(),
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SupportChatOverlay();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class SupportChatOverlay extends StatelessWidget {
  const SupportChatOverlay({super.key});

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
          padding: EdgeInsets.fromLTRB(12, 12, 12, wide ? 88 : 80),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: width,
              height: height,
              child: SupportChatPanel(
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SupportChatPanel extends ConsumerStatefulWidget {
  const SupportChatPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<SupportChatPanel> createState() => _SupportChatPanelState();
}

class _SupportChatPanelState extends ConsumerState<SupportChatPanel> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(supportChatProvider.notifier).open());
  }

  @override
  void dispose() {
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
    final text = _controller.text;
    _controller.clear();
    await ref.read(supportChatProvider.notifier).send(text);
    _scrollToEnd();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('support.deleteTitle'.tr()),
        content: Text('support.deleteBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('support.deleteKeep'.tr()),
          ),
          PressScale(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('support.deleteConfirm'.tr()),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(supportChatProvider.notifier).delete();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(supportChatProvider);
    ref.listen<SupportChatState>(supportChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToEnd();
      }
    });
    final busy = chat.loading || chat.sending;

    return Material(
      color: AppColors.card,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.support_agent_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'support.title'.tr(),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        chat.loading
                            ? 'common.loading'.tr()
                            : 'support.online'.tr(),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (chat.conversationId != null)
                  IconButton(
                    onPressed: chat.deleting ? null : _delete,
                    tooltip: 'support.delete'.tr(),
                    icon: chat.deleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            color: AppColors.muted,
                            size: 20,
                          ),
                  ),
                IconButton(
                  onPressed: widget.onClose,
                  tooltip: 'common.close'.tr(),
                  icon: const Icon(Icons.close, color: AppColors.muted, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Text(
              'support.subtitle'.tr(),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: chat.loading && chat.messages.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final message = chat.messages[index];
                      final fromUser = message.fromUser;
                      return Align(
                        alignment: fromUser
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
                            color: fromUser
                                ? AppColors.primary
                                : AppColors.background,
                            border: fromUser
                                ? null
                                : Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(10),
                              topRight: const Radius.circular(10),
                              bottomLeft: Radius.circular(fromUser ? 10 : 4),
                              bottomRight: Radius.circular(fromUser ? 4 : 10),
                            ),
                          ),
                          child: Text(
                            message.body,
                            style: TextStyle(
                              color: fromUser ? Colors.white : AppColors.navy,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (chat.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                chat.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !busy,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'support.inputHint'.tr(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: busy ? null : _send,
                  icon: chat.sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  tooltip: 'support.send'.tr(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
