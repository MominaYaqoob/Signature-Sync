import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/signature_model.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';

/// SCREEN C — Place Signature
class SignPlaceScreen extends StatefulWidget {
  const SignPlaceScreen({super.key});

  @override
  State<SignPlaceScreen> createState() => _SignPlaceScreenState();
}

class _SignPlaceScreenState extends State<SignPlaceScreen> {
  late List<SignatureModel> _signatures;
  int _selectedSig = 0;

  Offset _position = const Offset(40, 320);
  Size _stampSize = const Size(160, 64);
  double _rotation = 0;

  static const _minSize = Size(100, 44);
  static const _maxSize = Size(260, 110);

  @override
  void initState() {
    super.initState();
    _signatures = StorageService.getAllSignatures();
  }

  String get _name =>
      _signatures.isEmpty ? 'Signature' : _signatures[_selectedSig].name;

  Future<void> _pickSignature() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose signature',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_signatures.length, (i) {
                  final sig = _signatures[i];
                  final selected = i == _selectedSig;
                  return ListTile(
                    onTap: () => Navigator.pop(context, i),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: selected
                        ? AppColors.accentPurple.withValues(alpha: 0.14)
                        : null,
                    title: Text(
                      sig.name,
                      style: AppTextStyles.signaturePreview(
                        color: selected
                            ? AppColors.accentPurple
                            : AppColors.accentBlue,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.accentPurple,
                          )
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (index != null) setState(() => _selectedSig = index);
  }

  void _nudgeResize({required bool enlarge}) {
    setState(() {
      final factor = enlarge ? 1.12 : 0.9;
      final next = Size(
        (_stampSize.width * factor).clamp(_minSize.width, _maxSize.width),
        (_stampSize.height * factor).clamp(_minSize.height, _maxSize.height),
      );
      _stampSize = next;
    });
  }

  void _rotate() {
    setState(() => _rotation += math.pi / 12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: NavyAppHeader(
                title: 'Place Signature',
                onBack: () => context.pop(),
                fontSize: 15,
                trailing: Material(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => context.push('/sign-document/success'),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        'Apply',
                        style: AppTextStyles.onAccentLabel.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FC),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Agreement',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...List.generate(
                                    10,
                                    (i) => Padding(
                                      padding: const EdgeInsets.only(bottom: 9),
                                      child: Container(
                                        height: 7,
                                        width: i % 4 == 3 ? 120 : double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: _position.dx.clamp(
                              0,
                              constraints.maxWidth - _stampSize.width - 8,
                            ),
                            top: _position.dy.clamp(
                              0,
                              constraints.maxHeight - _stampSize.height - 8,
                            ),
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _position += details.delta;
                                });
                              },
                              child: Transform.rotate(
                                angle: _rotation,
                                child: SizedBox(
                                  width: _stampSize.width,
                                  height: _stampSize.height,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: _stampSize.width,
                                        height: _stampSize.height,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.55),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.accentPurple,
                                            width: 1.4,
                                          ),
                                        ),
                                        child: Text(
                                          _name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.signaturePreview(
                                            color: AppColors.accentPurpleDark,
                                            size: _stampSize.height * 0.55,
                                          ),
                                        ),
                                      ),
                                      ..._buildHandles(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ToolButton(
                      icon: Icons.gesture_rounded,
                      label: 'Signature',
                      onTap: _pickSignature,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToolButton(
                      icon: Icons.photo_size_select_large_rounded,
                      label: 'Resize',
                      onTap: () => _nudgeResize(enlarge: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToolButton(
                      icon: Icons.rotate_right_rounded,
                      label: 'Rotate',
                      onTap: _rotate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHandles() {
    const handleSize = 12.0;
    final positions = <Alignment>[
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];

    return positions.map((alignment) {
      return Align(
        alignment: alignment,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              final growX = details.delta.dx *
                  (alignment.x > 0 ? 1 : -1);
              final growY = details.delta.dy *
                  (alignment.y > 0 ? 1 : -1);
              _stampSize = Size(
                (_stampSize.width + growX)
                    .clamp(_minSize.width, _maxSize.width),
                (_stampSize.height + growY)
                    .clamp(_minSize.height, _maxSize.height),
              );
              if (alignment.x < 0) {
                _position = Offset(_position.dx + details.delta.dx, _position.dy);
              }
              if (alignment.y < 0) {
                _position = Offset(_position.dx, _position.dy + details.delta.dy);
              }
            });
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: AppColors.accentBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accentPurple, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
