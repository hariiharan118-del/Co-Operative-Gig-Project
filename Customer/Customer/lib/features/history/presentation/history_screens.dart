import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_error.dart';
import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/shimmer_skeletons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/domain/models.dart';
import '../../booking/presentation/active_booking_card.dart';
import '../../booking/presentation/payment_receipt_card.dart';
import '../../booking/providers/booking_providers.dart';
import '../../booking/providers/live_bookings_provider.dart';
import '../data/mock_bookings.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final bookingsAsync = ref.watch(myBookingsProvider);
    final live = ref.watch(liveBookingsProvider);
    final items = live.bookings;
    final hasBanner = ref.watch(activeBookingProvider) != null;
    final loading =
        bookingsAsync.isLoading && items.isEmpty && !isDemoSession(auth);

    return Scaffold(
      appBar: AppBar(title: Text('history.title'.tr())),
      body: loading
          ? const HistoryListSkeleton()
          : items.isEmpty && !hasBanner
          ? Center(
              child: InvitationEmpty(
                emoji: '📭',
                message: 'history.empty'.tr(),
                hint: 'history.emptyHint'.tr(),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length + (hasBanner ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (hasBanner && index == 0) {
                  return const ActiveBookingBanner(
                    padding: EdgeInsets.zero,
                  );
                }
                final booking = items[index - (hasBanner ? 1 : 0)];
                return StaggeredFadeSlide(
                  index: hasBanner ? index - 1 : index,
                  child: AppCard(
                    onTap: () => context.push('/history/${booking.id}'),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CategoryGlyph(
                              category: booking.categoryName,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                booking.categoryName,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            StatusChip(
                              label: statusLabel(booking.status),
                              emoji: statusEmoji(booking.status),
                              tone: booking.status == BookingStatus.cancelled
                                  ? AlertTone.error
                                  : booking.status == BookingStatus.completed
                                      ? AlertTone.info
                                      : AlertTone.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking.address.label,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            CategoryGlyph(
                              category: booking.categoryName,
                              size: 36,
                              borderRadius: 18,
                            ),
                            Expanded(
                              child: Text(
                                formatPaise(booking.totalPaise),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromList = ref.watch(liveBookingsProvider).bookings;
    final booking = bookingById(bookingId) ??
        fromList.where((item) => item.id == bookingId).firstOrNull;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Booking not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('history.detailTitle'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.categoryName,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(booking.id, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 10),
                StatusChip(
                  label: statusLabel(booking.status),
                  emoji: statusEmoji(booking.status),
                  tone: AlertTone.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('booking.address'.tr()),
                  subtitle: Text(booking.address.fullLine),
                ),
                if (booking.worker != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(booking.worker!.name),
                    subtitle: Text('★ ${booking.worker!.rating}'),
                    trailing: TextButton(
                      onPressed: () => context.push('/providers/prv_marcus/profile'),
                      child: const Text('Profile'),
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('history.total'.tr()),
                  subtitle: Text(formatPaise(booking.totalPaise)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (booking.isTrackable)
            PressScale(
              child: FilledButton(
                onPressed: () => context.push(booking.livePath, extra: booking),
                child: Text('tracking.title'.tr()),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.push('/history/${booking.id}/invoice'),
            child: Text('history.invoice'.tr()),
          ),
        ],
      ),
    );
  }
}

class InvoiceScreen extends ConsumerStatefulWidget {
  const InvoiceScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  PaymentReceipt? _receipt;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!looksLikeUuid(widget.bookingId) ||
        isDemoSession(ref.read(authProvider))) {
      setState(() => _loading = false);
      return;
    }
    try {
      final receipt =
          await ref.read(bookingsRepositoryProvider).getPayment(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = bookingById(widget.bookingId) ??
        ref.watch(liveBookingsProvider).byId(widget.bookingId);
    final receipt = _receipt;
    return Scaffold(
      appBar: AppBar(title: Text('history.invoiceTitle'.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (receipt != null)
                  PaymentReceiptCard(
                    receipt: receipt,
                    fallbackCategory: booking?.categoryName,
                    fallbackAmountPaise: booking?.totalPaise,
                  )
                else
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandHeader(compact: true),
                        const SizedBox(height: 16),
                        Text('Invoice #INV-${booking?.id ?? widget.bookingId}'),
                        Text(booking?.categoryName ?? ''),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error.toString()),
                        ],
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('history.total'.tr()),
                            Text(
                              formatPaise(booking?.totalPaise ?? 0),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
