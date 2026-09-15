enum SignatureStyle { drawn, typed, uploaded, scanned }

class SignatureModel {
  const SignatureModel({
    required this.id,
    required this.name,
    required this.style,
    required this.createdAt,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final SignatureStyle style;
  final DateTime createdAt;
  final bool isDefault;

  String get styleLabel => switch (style) {
        SignatureStyle.drawn => 'Drawn',
        SignatureStyle.typed => 'Typed',
        SignatureStyle.uploaded => 'Uploaded',
        SignatureStyle.scanned => 'Scanned',
      };

  SignatureModel copyWith({
    String? id,
    String? name,
    SignatureStyle? style,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return SignatureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Placeholder signatures for UI-only screens.
class DummySignatures {
  DummySignatures._();

  static List<SignatureModel> seed() => [
        SignatureModel(
          id: 'sig_aliza',
          name: 'Aliza',
          style: SignatureStyle.drawn,
          createdAt: DateTime(2026, 9, 1),
          isDefault: true,
        ),
        SignatureModel(
          id: 'sig_yaqoob',
          name: 'M. Yaqoob',
          style: SignatureStyle.typed,
          createdAt: DateTime(2026, 9, 3),
        ),
      ];

  static final List<SignatureModel> all = seed();
}
