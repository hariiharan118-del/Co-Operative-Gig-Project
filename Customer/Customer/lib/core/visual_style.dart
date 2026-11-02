import 'package:flutter/material.dart';

import 'theme.dart';

/// Color + emoji for each household service category.
class ServiceLook {
  const ServiceLook({
    required this.emoji,
    required this.color,
    required this.soft,
  });

  final String emoji;
  final Color color;
  final Color soft;
}

class ServiceLooks {
  ServiceLooks._();

  static const electrician = ServiceLook(
    emoji: '⚡',
    color: Color(0xFFC4841D),
    soft: Color(0xFFF8EDD8),
  );
  static const plumber = ServiceLook(
    emoji: '🔧',
    color: Color(0xFF2B6CB0),
    soft: Color(0xFFE4F0FA),
  );
  static const carpenter = ServiceLook(
    emoji: '🪚',
    color: Color(0xFFC05621),
    soft: Color(0xFFF8E6DC),
  );
  static const painter = ServiceLook(
    emoji: '🎨',
    color: Color(0xFFD05353),
    soft: Color(0xFFFBE4E4),
  );
  static const cleaner = ServiceLook(
    emoji: '🧹',
    color: Color(0xFF2A7A6A),
    soft: Color(0xFFE3F3EF),
  );
  static const domesticHelp = ServiceLook(
    emoji: '🏠',
    color: Color(0xFF7C6BB0),
    soft: Color(0xFFEDE8F7),
  );
  static const driver = ServiceLook(
    emoji: '🚗',
    color: Color(0xFF2C4A7C),
    soft: Color(0xFFE6EBF4),
  );
  static const gardener = ServiceLook(
    emoji: '🌱',
    color: Color(0xFF3D7A3C),
    soft: Color(0xFFE7F3E6),
  );
  static const caregiver = ServiceLook(
    emoji: '💝',
    color: Color(0xFFB44A6A),
    soft: Color(0xFFF8E4EB),
  );
  static const technician = ServiceLook(
    emoji: '🛠️',
    color: Color(0xFF5A6570),
    soft: Color(0xFFE8EBEE),
  );

  static ServiceLook of(String? raw) {
    final key = (raw ?? '').toLowerCase();
    if (key.contains('electric')) return electrician;
    if (key.contains('plumb')) return plumber;
    if (key.contains('carpent') || key.contains('wood')) return carpenter;
    if (key.contains('paint')) return painter;
    if (key.contains('clean')) return cleaner;
    if (key.contains('domestic') ||
        key.contains('maid') ||
        key.contains('housekeep') ||
        key.contains('home help')) {
      return domesticHelp;
    }
    if (key.contains('driv') || key.contains('cab') || key.contains('taxi')) {
      return driver;
    }
    if (key.contains('garden') ||
        key.contains('yard') ||
        key.contains('landscap')) {
      return gardener;
    }
    if (key.contains('care') || key.contains('nurs') || key.contains('elder')) {
      return caregiver;
    }
    return technician;
  }
}

/// Category color wash with that category's image (emoji if the asset is missing).
class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({
    super.key,
    required this.category,
    this.slug,
    this.size = 44,
    this.borderRadius,
    this.circular = false,
    this.photoUrl,
  });

  final String category;
  final String? slug;
  final double size;
  final double? borderRadius;
  final bool circular;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final look = ServiceLooks.of(category);
    final emoji = Text(
      look.emoji,
      style: TextStyle(fontSize: size * 0.46, height: 1),
    );
    final inner = size >= 64 ? 32.0 : (size * 0.5).clamp(18.0, 32.0);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: circular ? look.color : look.soft,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular
            ? null
            : BorderRadius.circular(borderRadius ?? size * 0.32),
      ),
      clipBehavior: Clip.antiAlias,
      child: _glyphChild(inner: inner, emoji: emoji),
    );
  }

  Widget _glyphChild({required double inner, required Widget emoji}) {
    final network = photoUrl?.trim();
    if (network != null && network.isNotEmpty) {
      return Image.network(
        network,
        width: inner,
        height: inner,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _assetOrEmoji(inner, emoji),
      );
    }
    return _assetOrEmoji(inner, emoji);
  }

  Widget _assetOrEmoji(double inner, Widget emoji) {
    return Image.asset(
      categoryImageAssetPath(slug: slug, name: category),
      width: inner,
      height: inner,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => emoji,
    );
  }
}

String categoryImageAssetPath({String? slug, String? name}) {
  final resolved = (slug ?? '').trim().isNotEmpty
      ? slug!.trim().toLowerCase()
      : categoryImageSlug(name);
  return 'assets/images/categories/$resolved.png';
}

/// Cover photo for listing cards. Missing files fall back via [Image.asset] errorBuilder.
String categoryPhotoAssetPath({String? slug, String? name}) {
  final resolved = (slug ?? '').trim().isNotEmpty
      ? slug!.trim().toLowerCase().replaceAll('-', '_')
      : categoryImageSlug(name);
  return 'assets/images/services/$resolved.jpg';
}

String categoryImageSlug(String? raw) {
  final key = (raw ?? '').toLowerCase();
  if (key.contains('electric')) return 'electrician';
  if (key.contains('plumb')) return 'plumber';
  if (key.contains('carpent') || key.contains('wood')) return 'carpenter';
  if (key.contains('paint')) return 'painter';
  if (key.contains('domestic') ||
      key.contains('maid') ||
      key.contains('housekeep') ||
      key.contains('home help')) {
    return 'domestic-help';
  }
  if (key.contains('clean')) return 'cleaner';
  if (key.contains('driv') || key.contains('cab') || key.contains('taxi')) {
    return 'driver';
  }
  if (key.contains('garden') ||
      key.contains('yard') ||
      key.contains('landscap')) {
    return 'gardener';
  }
  if (key.contains('care') || key.contains('nurs') || key.contains('elder')) {
    return 'caregiver';
  }
  if (key.contains('ac') || key.contains('hvac')) return 'ac_repair';
  if (key.contains('appliance') || key.contains('kitchen')) return 'appliance';
  if (key.contains('pest')) return 'pest';
  return 'technician';
}

const _avatarPalette = <Color>[
  Color(0xFF17707D),
  Color(0xFF2B6CB0),
  Color(0xFFC05621),
  Color(0xFF7C6BB0),
  Color(0xFFB44A6A),
  Color(0xFF2A7A6A),
  Color(0xFFC4841D),
  Color(0xFF2C4A7C),
];

Color avatarColorFor(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return _avatarPalette.first;
  var hash = 0;
  for (final unit in trimmed.codeUnits) {
    hash = 0x1fffffff & (hash * 31 + unit);
  }
  return _avatarPalette[hash.abs() % _avatarPalette.length];
}

String initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

class NameAvatar extends StatelessWidget {
  const NameAvatar({
    super.key,
    required this.name,
    this.initials,
    this.photoUrl,
    this.size = 48,
    this.borderRadius,
  });

  final String name;
  final String? initials;
  final String? photoUrl;
  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: avatarColorFor(name),
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius == null ? null : BorderRadius.circular(radius),
      ),
      child: Text(
        (initials ?? initialsFor(name)).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );

    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: radius == null
          ? BorderRadius.circular(size / 2)
          : BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

String? statusEmojiFor(String label) {
  final key = label.toLowerCase();
  if (key.contains('cancel')) return '🚫';
  if (key.contains('not approved') ||
      key.contains('not enrolled') ||
      key.contains('reject') ||
      key.contains('inactive') ||
      key.contains('suspend')) {
    return '❌';
  }
  if (key.contains('assigned')) return '🟡';
  if (key.contains('docs missing') || key.contains('info requested')) {
    return '📄';
  }
  if (key.contains('pending') ||
      key.contains('submitted') ||
      key.contains('requested') ||
      key.contains('finding') ||
      key.contains('review needed') ||
      key.contains('waiting')) {
    return '⏳';
  }
  if (key.contains('on the way') ||
      key.contains('en route') ||
      key.contains('en-route')) {
    return '🚗';
  }
  if (key.contains('arrived')) return '📍';
  if (key.contains('in progress')) return '🔧';
  if (key.contains('approved') ||
      key.contains('enrolled') ||
      key.contains('completed') ||
      key.contains('paid') ||
      key.contains('ready') ||
      key.contains('active')) {
    return '✅';
  }
  return null;
}

class InvitationEmpty extends StatelessWidget {
  const InvitationEmpty({
    super.key,
    required this.emoji,
    required this.message,
    this.hint,
  });

  final String emoji;
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 42, height: 1)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
