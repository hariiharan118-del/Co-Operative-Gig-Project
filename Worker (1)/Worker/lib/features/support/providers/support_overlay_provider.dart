import 'package:flutter_riverpod/flutter_riverpod.dart';

final supportOverlayProvider =
    NotifierProvider<SupportOverlayNotifier, bool>(SupportOverlayNotifier.new);

class SupportOverlayNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;

  void close() => state = false;

  void toggle() => state = !state;
}
