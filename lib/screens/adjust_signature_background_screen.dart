import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';

import '../services/signature_background.dart';
import '../theme/signature_fonts.dart';
import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/signature_inputs.dart';
import '../widgets/transparency_checkerboard.dart';

/// Shown after cropping a scanned/gallery signature photo. Lets the user see
/// the background-removal result live and fine-tune it before saving, since
/// a single fixed threshold doesn't work for every paper/lighting/pen.
///
/// Pops with the final transparent PNG bytes, or `null` if the user backs
/// out without using this capture.
class AdjustSignatureBackgroundScreen extends StatefulWidget {
  const AdjustSignatureBackgroundScreen({super.key, required this.sourceBytes});

  /// The cropped photo, before background removal.
  final Uint8List sourceBytes;

  @override
  State<AdjustSignatureBackgroundScreen> createState() =>
      _AdjustSignatureBackgroundScreenState();
}

class _AdjustSignatureBackgroundScreenState
    extends State<AdjustSignatureBackgroundScreen> {
  double _threshold = kDefaultPaperThreshold.toDouble();
  int _inkIndex = 0;
  Uint8List? _preview;
  bool _processing = true;
  String? _error;
  Timer? _debounce;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    _reprocess(immediate: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _reprocess({bool immediate = false}) {
    _debounce?.cancel();
    setState(() => _processing = true);
    if (immediate) {
      _runCompute();
    } else {
      _debounce = Timer(const Duration(milliseconds: 120), _runCompute);
    }
  }

  Future<void> _runCompute() async {
    final generation = ++_generation;
    final params = BackgroundRemovalParams(
      bytes: widget.sourceBytes,
      paperThreshold: _threshold.round(),
      inkColorValue: kInkColors[_inkIndex].color.toARGB32(),
    );
    try {
      final result = await compute(removeSignatureBackground, params);
      if (!mounted || generation != _generation) return;
      if (result == null) {
        setState(() {
          _processing = false;
          _error = 'Could not read this photo — try a clearer shot';
        });
        return;
      }
      setState(() {
        _preview = result;
        _processing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _processing = false;
        _error = 'Could not process this photo: $e';
      });
    }
  }

  void _useSignature() {
    final bytes = _preview;
    if (bytes == null) return;
    final cropped = cropTransparentMargins(bytes);
    Navigator.of(context).pop(cropped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavyAppHeader(
                title: 'Adjust Background',
                onBack: () => Navigator.of(context).pop(),
                fontSize: 15,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The checkered area shows where the background is removed. '
                'Drag the slider until only your ink is left.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: TransparencyCheckerboard(
                  child: Center(
                    child: _error != null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                          )
                        : _preview == null
                            ? const CircularProgressIndicator(
                                color: AppColors.accentPurple,
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Image.memory(
                                      _preview!,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                  if (_processing)
                                    const Positioned(
                                      top: 10,
                                      right: 10,
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.accentPurple,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    'Background removal',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Keep more',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                  Text(
                    '  ·  ',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                  Text(
                    'Remove more',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.accentPurple,
                  thumbColor: AppColors.accentPurple,
                  overlayColor: AppColors.accentPurple.withValues(alpha: 0.15),
                  inactiveTrackColor: AppColors.borderSoft,
                ),
                child: Slider(
                  value: _threshold,
                  min: kPaperThresholdMin.toDouble(),
                  max: kPaperThresholdMax.toDouble(),
                  onChanged: (value) {
                    setState(() => _threshold = value);
                    _reprocess();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              InkPicker(
                selected: _inkIndex,
                onSelect: (i) {
                  setState(() => _inkIndex = i);
                  _reprocess();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 52,
                child: PressableScale(
                  onTap: (_preview == null || _processing) ? null : _useSignature,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Opacity(
                    opacity: (_preview == null || _processing) ? 0.55 : 1,
                    child: DecoratedBox(
                      decoration: AppDecorations.purpleButton(
                        radius: AppRadii.sm,
                      ),
                      child: Center(
                        child: Text(
                          'Use this signature',
                          style: AppTextStyles.onAccentLabel.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
