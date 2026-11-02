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

/// Category color wash with that category's emoji.
class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({
    super.key,
    required this.category,
    this.size = 44,
    this.borderRadius,
  });

  final String category;
  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final look = ServiceLooks.of(category);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: look.soft,
        borderRadius: BorderRadius.circular(borderRadius ?? size * 0.32),
      ),
      child: Text(
        look.emoji,
        style: TextStyle(fontSize: size * 0.46, height: 1),
      ),
    );
  }
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
    this.size = 48,
    this.borderRadius,
  });

  final String name;
  final String? initials;
  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius;
    return Container(
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
