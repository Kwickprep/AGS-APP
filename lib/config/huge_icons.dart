import 'package:flutter/material.dart';

/// HugeIcons Pro - Stroke Rounded
///
/// IMPORTANT: These icons are currently using Material Icons as fallback.
///
/// To use actual HugeIcons, you need to:
/// 1. Download the HugeIcons font file (HugeIcons.ttf)
/// 2. Place it in assets/fonts/
/// 3. Register it in pubspec.yaml under fonts section
/// 4. Update the unicode values below with actual HugeIcons unicode points
/// 5. Change _USE_FALLBACK to false
///
/// See HUGEICONS_SETUP.md for detailed instructions

class HugeIcons {
  HugeIcons._();

  // Set to false when you have the HugeIcons font properly configured
  static const bool _useFallback = true;

  static const _kFontFam = 'HugeIcons';
  static const String? _kFontPkg = null;

  // Menu Icons Mapping
  // Format: HugeIcons name -> Fallback Material Icon

  /// analytics-01 icon (Dashboard)
  static const IconData analytics01 = _useFallback
      ? Icons.analytics_outlined
      : IconData(0xe800, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// message-question icon (Inquiries)
  static const IconData messageQuestion = _useFallback
      ? Icons.question_answer_outlined
      : IconData(0xe801, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// package icon (Products)
  static const IconData package = _useFallback
      ? Icons.inventory_2_outlined
      : IconData(0xe802, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// colors icon (Themes)
  static const IconData colors = _useFallback
      ? Icons.palette_outlined
      : IconData(0xe803, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// orthogonal-edge icon (Categories)
  static const IconData orthogonalEdge = _useFallback
      ? Icons.category_outlined
      : IconData(0xe804, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// award-03 icon (Brands)
  static const IconData award03 = _useFallback
      ? Icons.emoji_events_outlined
      : IconData(0xe805, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  static const IconData hamBurger = _useFallback
      ? Icons.menu
      : IconData(0xe805, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// tag-01 icon (Tags)
  static const IconData tag01 = _useFallback
      ? Icons.local_offer_outlined
      : IconData(0xe806, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// share-07 icon (Activity Types)
  static const IconData share07 = _useFallback
      ? Icons.share_outlined
      : IconData(0xe807, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// chart-column icon (Activities)
  static const IconData chartColumn = _useFallback
      ? Icons.bar_chart_outlined
      : IconData(0xe808, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// user-multiple-02 icon (Users)
  static const IconData userMultiple02 = _useFallback
      ? Icons.people_outlined
      : IconData(0xe809, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// user-group icon (Groups)
  static const IconData userGroup = _useFallback
      ? Icons.groups_outlined
      : IconData(0xe80a, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// bandage icon (Companies)
  static const IconData bandage = _useFallback
      ? Icons.business_outlined
      : IconData(0xe80b, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// message-01 icon (Messages)
  static const IconData message01 = _useFallback
      ? Icons.message_outlined
      : IconData(0xe80c, fontFamily: _kFontFam, fontPackage: _kFontPkg);
}
