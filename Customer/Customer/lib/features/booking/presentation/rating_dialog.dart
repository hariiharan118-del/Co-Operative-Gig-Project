import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_error.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models.dart';
import '../providers/booking_providers.dart';
import '../providers/live_bookings_provider.dart';

Future<bool> showBookingRatingDialog(
  BuildContext context, {
  required Booking booking,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => BookingRatingDialog(booking: booking),
  );
  return result == true;
}

class BookingRatingDialog extends ConsumerStatefulWidget {
  const BookingRatingDialog({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<BookingRatingDialog> createState() => _BookingRatingDialogState();
}

class _BookingRatingDialogState extends ConsumerState<BookingRatingDialog> {
  final _feedback = TextEditingController();
  int _stars = 0;
  int _hovered = 0;
  int _popStar = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  int get _preview => _hovered > 0 ? _hovered : _stars;

  Future<void> _submit() async {
    if (_stars < 1 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authProvider);
      if (!isDemoSession(auth)) {
        await ref.read(bookingsRepositoryProvider).submitRating(
              widget.booking.id,
              rating: _stars,
              feedback: _feedback.text,
            );
      }
      ref.read(liveBookingsProvider.notifier).markCustomerRated(widget.booking.id);
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _busy = false;
        _error = error is ApiException ? error.message : error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final workerName = widget.booking.worker?.name.trim();
    final name = (workerName != null && workerName.isNotEmpty)
        ? workerName
        : 'tracking.workerFallback'.tr();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'rating.title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'rating.subtitle'.tr(args: [name]),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    MouseRegion(
                      onEnter: (_) => setState(() => _hovered = i),
                      onExit: (_) => setState(() => _hovered = 0),
                      child: IconButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _stars = i;
                                  _popStar = i;
                                }),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        iconSize: 36,
                        icon: AnimatedScale(
                          scale: _popStar == i ? 1.2 : 1,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          onEnd: () {
                            if (_popStar == i && mounted) {
                              setState(() => _popStar = 0);
                            }
                          },
                          child: Icon(
                            i <= _preview
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: i <= _preview
                                ? AppColors.starFilled
                                : AppColors.starEmpty,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feedback,
                enabled: !_busy,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'rating.feedbackHint'.tr(),
                  counterText: '',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              PressScale(
                enabled: _stars >= 1 && !_busy,
                child: FilledButton(
                  onPressed: _stars < 1 || _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text('rating.submit'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
