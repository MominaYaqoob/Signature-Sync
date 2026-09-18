import 'dart:io';

import 'package:flutter/material.dart';

import '../models/signature_model.dart';
import '../theme/theme.dart';

/// Renders a saved signature as [Image.file] when [imagePath] exists,
/// otherwise as styled cursive text (auto/typed signatures).
class SignatureVisual extends StatelessWidget {
  const SignatureVisual({
    super.key,
    required this.name,
    this.imagePath,
    this.color = AppColors.accentPurple,
    this.fontSize = 28,
    this.maxLines = 1,
    this.fit = BoxFit.contain,
  });

  factory SignatureVisual.fromModel(
    SignatureModel signature, {
    Color color = AppColors.accentPurple,
    double fontSize = 28,
    int maxLines = 1,
    BoxFit fit = BoxFit.contain,
  }) {
    return SignatureVisual(
      name: signature.name,
      imagePath: signature.imagePath,
      color: color,
      fontSize: fontSize,
      maxLines: maxLines,
      fit: fit,
    );
  }

  final String name;
  final String? imagePath;
  final Color color;
  final double fontSize;
  final int maxLines;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _textFallback(),
      );
    }
    return _textFallback();
  }

  Widget _textFallback() {
    return Text(
      name,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.signaturePreview(
        color: color,
        size: fontSize,
      ),
    );
  }
}
