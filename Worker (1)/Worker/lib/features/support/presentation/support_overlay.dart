import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/support_chat_provider.dart';
import '../providers/support_overlay_provider.dart';

class SupportOverlayHost extends ConsumerWidget {
  const SupportOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final authed = auth is AuthAuthenticated &&
        !auth.session.accessToken.startsWith('demo-');
    final open = ref.watch(supportOverlayProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (authed)
          Positioned(
            right: 16,
            bottom: 88,
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (open) ...[
                    const SupportChatCard(),
                    const SizedBox(height: 10),
                  ],
                  FloatingActionButton(
                    heroTag: 'support-fab',
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    onPressed: () =>
                        ref.read(supportOverlayProvider.notifier).toggle(),
                    child: Icon(open ? Icons.close : Icons.chat_bubble_outline),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SupportChatCard extends ConsumerStatefulWidget {
  const SupportChatCard({super.key});

  @override
  ConsumerState<SupportChatCard> createState() => _SupportChatCardState();
}

class _SupportChatCardState extends ConsumerState<SupportChatCard> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(supportChatProvider.notifier).open());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(supportChatProvider.notifier).send(text);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('support.deleteTitle'.tr()),
        content: Text('support.deleteBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref.read(supportChatProvider.notifier).deleteConversation();
    if (success && mounted) {
      ref.read(supportOverlayProvider.notifier).close();
    }
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
      color: Colors.transparent,
      child: Container(
        width: 320,
        height: 380,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'support.title'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'support.subtitle'.tr(),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (chat.conversationId != null &&
                      chat.conversationId!.isNotEmpty)
                    CircleIconButton(
                      icon: Icons.delete_outline,
                      size: 32,
                      foreground: AppColors.danger,
                      onPressed: chat.deleting ? null : _confirmDelete,
                    ),
                  CircleIconButton(
                    icon: Icons.close,
                    size: 32,
                    onPressed: () =>
                        ref.read(supportOverlayProvider.notifier).close(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: chat.loading && chat.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
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
                            constraints: const BoxConstraints(maxWidth: 240),
                            decoration: BoxDecoration(
                              color:
                                  fromUser ? AppColors.accent : AppColors.canvas,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message.body,
                              style: TextStyle(
                                color:
                                    fromUser ? Colors.white : AppColors.ink,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (chat.needsSignIn || chat.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Text(
                  chat.needsSignIn
                      ? 'support.signInRequired'.tr()
                      : chat.error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !busy && !chat.needsSignIn,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
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
                    onPressed: busy || chat.needsSignIn ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
