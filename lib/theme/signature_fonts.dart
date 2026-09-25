import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SignatureFontCategory {
  signature('Signature'),
  elegant('Elegant'),
  handwritten('Handwritten'),
  bold('Bold');

  const SignatureFontCategory(this.label);
  final String label;
}

/// A cursive font offered for typed signatures. [family] is the Google Fonts
/// family name (the .ttf is bundled under assets/google_fonts/).
class SignatureFont {
  const SignatureFont(this.family, this.category, {this.scale = 1.0});

  final String family;
  final SignatureFontCategory category;

  /// Visual size correction — some scripts draw much smaller/larger than
  /// others at the same font size.
  final double scale;

  TextStyle style({required double fontSize, required Color color}) =>
      GoogleFonts.getFont(
        family,
        fontSize: fontSize * scale,
        color: color,
        height: 1.2,
      );
}

const kSignatureFonts = <SignatureFont>[
  // Realistic autograph-style scripts.
  SignatureFont('Mr De Haviland', SignatureFontCategory.signature, scale: 1.25),
  SignatureFont('Monsieur La Doulaise', SignatureFontCategory.signature,
      scale: 1.1),
  SignatureFont('Herr Von Muellerhoff', SignatureFontCategory.signature,
      scale: 1.3),
  SignatureFont('Mrs Saint Delafield', SignatureFontCategory.signature,
      scale: 1.2),
  SignatureFont('Qwigley', SignatureFontCategory.signature, scale: 1.4),
  SignatureFont('Whisper', SignatureFontCategory.signature, scale: 1.2),
  SignatureFont('Birthstone', SignatureFontCategory.signature, scale: 1.1),
  // Formal calligraphy.
  SignatureFont('Great Vibes', SignatureFontCategory.elegant),
  SignatureFont('Alex Brush', SignatureFontCategory.elegant),
  SignatureFont('Parisienne', SignatureFontCategory.elegant),
  SignatureFont('Pinyon Script', SignatureFontCategory.elegant, scale: 0.9),
  SignatureFont('Allura', SignatureFontCategory.elegant, scale: 1.1),
  SignatureFont('Italianno', SignatureFontCategory.elegant, scale: 1.25),
  SignatureFont('Arizonia', SignatureFontCategory.elegant),
  SignatureFont('Rouge Script', SignatureFontCategory.elegant, scale: 1.1),
  // Natural pen handwriting.
  SignatureFont('Homemade Apple', SignatureFontCategory.handwritten,
      scale: 0.75),
  SignatureFont('La Belle Aurore', SignatureFontCategory.handwritten,
      scale: 0.9),
  SignatureFont('Cedarville Cursive', SignatureFontCategory.handwritten,
      scale: 0.85),
  SignatureFont('Kristi', SignatureFontCategory.handwritten, scale: 1.1),
  SignatureFont('Sacramento', SignatureFontCategory.handwritten, scale: 1.15),
  SignatureFont('Dancing Script', SignatureFontCategory.handwritten),
  // Heavier strokes.
  SignatureFont('Satisfy', SignatureFontCategory.bold, scale: 0.95),
  SignatureFont('Yellowtail', SignatureFontCategory.bold, scale: 0.95),
  SignatureFont('Pacifico', SignatureFontCategory.bold, scale: 0.8),
];

/// Looks up a font by the label stored on a signature (case-insensitive).
SignatureFont? signatureFontByLabel(String? label) {
  final key = (label ?? '').trim().toLowerCase();
  if (key.isEmpty) return null;
  for (final font in kSignatureFonts) {
    if (font.family.toLowerCase() == key) return font;
  }
  return null;
}

/// Ink colours offered for typed signatures (stored as ARGB ints).
const kInkColors = <({String label, Color color})>[
  (label: 'Black', color: Color(0xFF111111)),
  (label: 'Blue', color: Color(0xFF1D4ED8)),
  (label: 'Navy', color: Color(0xFF1A2744)),
];
