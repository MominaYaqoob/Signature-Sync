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

  String get styleLabel => switch (style) {
        SignatureStyle.drawn => 'Drawn',
        SignatureStyle.typed => 'Typed',
        SignatureStyle.uploaded => 'Uploaded',
        SignatureStyle.scanned => 'Scanned',
      };

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  SignatureModel copyWith({
    String? id,
    String? name,
    SignatureStyle? style,
    DateTime? createdAt,
    bool? isDefault,
    String? imagePath,
  }) {
    return SignatureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
