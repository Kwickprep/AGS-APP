# HugeIcons Setup Guide for Flutter

This project uses **HugeIcons Pro (Stroke Rounded)** for the navigation drawer icons.

## Setup Instructions

### Option 1: Using HugeIcons Font File (Recommended)

#### Step 1: Obtain the HugeIcons Font File

1. If you have purchased HugeIcons Pro, download the font file (`.ttf` format)
2. The font file should be named something like `HugeIcons.ttf` or `HugeIconsStrokeRounded.ttf`

#### Step 2: Add Font to Project

1. Create a fonts directory in your assets folder:
   ```
   mkdir -p assets/fonts
   ```

2. Copy the HugeIcons font file to `assets/fonts/HugeIcons.ttf`

#### Step 3: Register Font in pubspec.yaml

Add the following to your `pubspec.yaml` file under the `flutter:` section:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/

  # Add this fonts section
  fonts:
    - family: HugeIcons
      fonts:
        - asset: assets/fonts/HugeIcons.ttf
```

#### Step 4: Update Unicode Values

The file `lib/config/huge_icons.dart` contains placeholder unicode values. You need to update these with the actual unicode code points from your HugeIcons font.

**To find the correct unicode values:**

1. **Method 1: Using Font Viewer Tools**
   - On Windows: Open the `.ttf` file with Font Viewer
   - On Mac: Open with Font Book
   - Look for the unicode/character map to find each icon's code point

2. **Method 2: From HugeIcons Documentation**
   - Check the HugeIcons documentation or font file metadata
   - They usually provide a mapping of icon names to unicode values

3. **Method 3: Using Online Tools**
   - Upload the font to fontdrop.info or similar tools
   - View the glyph map to find unicode values

**Update the IconData values in `lib/config/huge_icons.dart`:**

```dart
// Example - replace 0xe800 with actual unicode value
static const IconData analytics01 = IconData(0xe800, fontFamily: _kFontFam, fontPackage: _kFontPkg);
```

#### Current Icon Mapping

| Icon Name (Code) | Icon Display Name | Menu Item |
|------------------|-------------------|-----------|
| `analytics-01` | Analytics | Dashboard |
| `message-question` | Message Question | Inquiries |
| `package` | Package | Products |
| `colors` | Colors | Themes |
| `orthogonal-edge` | Orthogonal Edge | Categories |
| `award-03` | Award | Brands |
| `tag-01` | Tag | Tags |
| `share-07` | Share | Activity Types |
| `chart-column` | Chart Column | Activities |
| `user-multiple-02` | User Multiple | Users |
| `user-group` | User Group | Groups |
| `bandage` | Bandage | Companies |

---

### Option 2: Using a HugeIcons Flutter Package

If there's a HugeIcons package available on pub.dev:

1. **Add dependency to pubspec.yaml:**
   ```yaml
   dependencies:
     hugeicons: ^latest_version  # Check pub.dev for actual package name
   ```

2. **Update lib/config/huge_icons.dart:**
   ```dart
   // Import the package
   import 'package:hugeicons/hugeicons.dart';

   class HugeIcons {
     // Use icons from the package
     static const IconData analytics01 = HugeIconsStroke.analytics01;
     // ... etc
   }
   ```

3. **Run:**
   ```bash
   flutter pub get
   ```

---

### Option 3: Fallback to Material Icons (Temporary)

If you don't have access to HugeIcons yet, you can temporarily use Material Icons by updating `lib/config/huge_icons.dart`:

```dart
import 'package:flutter/material.dart';

class HugeIcons {
  // Temporary fallback to Material Icons
  static const IconData analytics01 = Icons.analytics_outlined;
  static const IconData messageQuestion = Icons.question_answer_outlined;
  static const IconData package = Icons.inventory_2_outlined;
  static const IconData colors = Icons.palette_outlined;
  static const IconData orthogonalEdge = Icons.category_outlined;
  static const IconData award03 = Icons.emoji_events_outlined;
  static const IconData tag01 = Icons.local_offer_outlined;
  static const IconData share07 = Icons.share_outlined;
  static const IconData chartColumn = Icons.bar_chart_outlined;
  static const IconData userMultiple02 = Icons.people_outlined;
  static const IconData userGroup = Icons.groups_outlined;
  static const IconData bandage = Icons.business_outlined;
}
```

---

## Verification

After setup, run the app to verify the icons appear correctly in the drawer:

```bash
flutter run
```

If icons show as empty boxes (□), it means:
- The font file is not properly loaded
- The unicode values are incorrect
- The font family name doesn't match

## Troubleshooting

### Icons showing as boxes
1. Verify the font file path in `pubspec.yaml` is correct
2. Run `flutter clean && flutter pub get`
3. Check that unicode values match the font's character map

### Build errors
1. Ensure proper indentation in `pubspec.yaml`
2. Font file must be in `assets/fonts/` directory
3. Run `flutter pub get` after modifying `pubspec.yaml`

### Icons not updating
1. Hot reload may not work for font changes
2. Stop the app and run `flutter run` again
3. Try `flutter clean` if issues persist

## Additional Resources

- [HugeIcons Official Website](https://hugeicons.com/)
- [Flutter Custom Fonts Documentation](https://docs.flutter.dev/cookbook/design/fonts)
- [Flutter IconData Class](https://api.flutter.dev/flutter/widgets/IconData-class.html)
