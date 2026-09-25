import 'package:hive/hive.dart';

part 'signature_model.g.dart';

@HiveType(typeId: 2)
enum SignatureStyle {
  @HiveField(0)
  drawn,
  @HiveField(1)
  typed,
  @HiveField(2)
  uploaded,
  @HiveField(3)
  scanned,
  @HiveField(4)
  generated,
}

@HiveType(typeId: 0)
class SignatureModel {
  const SignatureModel({
    required this.id,
    required this.name,
    required this.style,
    required this.createdAt,
    this.isDefault = false,
    this.imagePath,
    this.signatureText,
    this.fontLabel,
    this.inkColor,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final SignatureStyle style;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final bool isDefault;

  /// Local PNG path for hand-drawn signatures; null for font-based ones.
  @HiveField(5)
  final String? imagePath;

  /// Text rendered for typed/auto signatures (e.g. "Aliza Khan").
  /// [name] is the user's label for the signature ("Work signature").
  @HiveField(6)
  final String? signatureText;

  /// Font template label chosen for typed signatures (e.g. "Great Vibes").
  @HiveField(7)
  final String? fontLabel;

  /// Ink colour (ARGB) chosen for typed signatures; null uses the UI accent.
  @HiveField(8)
  final int? inkColor;

  /// What to draw for text-based signatures; older records fall back to [name].
  String get displayText {
    final text = signatureText?.trim() ?? '';
    return text.isEmpty ? name : text;
  }

  String get styleLabel => switch (style) {
        SignatureStyle.drawn => 'Drawn',
        SignatureStyle.typed => 'Typed',
        SignatureStyle.uploaded => 'Uploaded',
        SignatureStyle.scanned => 'Scanned',
        SignatureStyle.generated => 'Generated',
      };

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  SignatureModel copyWith({
    String? id,
    String? name,
    SignatureStyle? style,
    DateTime? createdAt,
    bool? isDefault,
    String? imagePath,
    String? signatureText,
    String? fontLabel,
    int? inkColor,
  }) {
    return SignatureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
      imagePath: imagePath ?? this.imagePath,
      signatureText: signatureText ?? this.signatureText,
      fontLabel: fontLabel ?? this.fontLabel,
      inkColor: inkColor ?? this.inkColor,
    );
  }
}
