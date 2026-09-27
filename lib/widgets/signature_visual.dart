import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/signature_model.dart';
import '../services/signature_image_store.dart';
import '../theme/signature_fonts.dart';
import '../theme/theme.dart';
import 'transparency_checkerboard.dart';

/// Cursive text style for a typed signature's font template label
/// ("Great Vibes", "Dancing Script", …). Unknown labels use the app default.
TextStyle signatureFontStyle(
  String? fontLabel, {
  required double fontSize,
  required Color color,
}) {
  final font = signatureFontByLabel(fontLabel);
  if (font != null) return font.style(fontSize: fontSize, color: color);

  // Older records / template labels.
  final label = (fontLabel ?? '').toLowerCase();
  if (label.contains('sacramento')) {
    return GoogleFonts.sacramento(fontSize: fontSize, color: color);
  }
  if (label.contains('pacifico')) {
    return GoogleFonts.pacifico(fontSize: fontSize, color: color);
  }
  if (label.contains('allura')) {
    return GoogleFonts.allura(fontSize: fontSize, color: color);
  }
  if (label.contains('dancing')) {
    return GoogleFonts.dancingScript(fontSize: fontSize, color: color);
  }
  return AppTextStyles.signaturePreview(color: color, size: fontSize);
}

/// Renders a saved signature as [Image.file] when [imagePath] exists,
/// otherwise as styled cursive text (auto/typed signatures).
class SignatureVisual extends StatelessWidget {
  const SignatureVisual({
    super.key,
    required this.name,
    this.imagePath,
    this.fontLabel,
    this.color = AppColors.accentPurple,
    this.fontSize = 28,
    this.maxLines = 1,
    this.fit = BoxFit.contain,
    this.showTransparencyGrid = false,
  });

  factory SignatureVisual.fromModel(
    SignatureModel signature, {
    Color color = AppColors.accentPurple,
    double fontSize = 28,
    int maxLines = 1,
    BoxFit fit = BoxFit.contain,
    bool showTransparencyGrid = false,
  }) {
    return SignatureVisual(
      name: signature.displayText,
      imagePath: signature.imagePath,
      fontLabel: signature.fontLabel,
      color: signature.inkColor != null ? Color(signature.inkColor!) : color,
      fontSize: fontSize,
      maxLines: maxLines,
      fit: fit,
      showTransparencyGrid: showTransparencyGrid,
    );
  }

  final String name;
  final String? imagePath;
  final String? fontLabel;
  final Color color;
  final double fontSize;
  final int maxLines;
  final BoxFit fit;

  /// When true, image signatures sit on a checkerboard so removed paper
  /// (alpha) is visible — opaque white cards make transparency look like
  /// paper came back.
  final bool showTransparencyGrid;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && SignatureImageStore.exists(path)) {
      final image = SignatureImageStore.image(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => _textFallback(),
      );
      if (!showTransparencyGrid) return image;
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: TransparencyCheckerboard(
          cellSize: 8,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: image,
          ),
        ),
      );
    }
    return _textFallback();
  }

  Widget _textFallback() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: signatureFontStyle(fontLabel, fontSize: fontSize, color: color),
      ),
    );
  }
}
