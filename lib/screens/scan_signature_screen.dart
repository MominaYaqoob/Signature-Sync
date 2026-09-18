import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';

class ScanSignatureScreen extends StatelessWidget {
  const ScanSignatureScreen({super.key});

  static const _previewBg = Color(0xFF17181C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _previewBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder "camera" feed — subtle vignette / grain feel.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  const Color(0xFF2A2C32),
                  _previewBg,
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Soft faux focus plane
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: NavyAppHeader(
                    title: 'Scan Signature',
                    onBack: () => context.pop(),
                    fontSize: 15,
                  ),
                ),
                const Spacer(flex: 2),
                const _ScanFrame(
                  width: 280,
                  height: 168,
                ),
                const SizedBox(height: 18),
                Text(
                  'Align signature within frame',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(flex: 3),
                _CaptureButton(
                  onPressed: () {
                    context.push(
                      '/save-signature',
                      extra: <String, String>{
                        'name': 'Scanned signature',
                        'style': 'Scanned',
                        'source': 'scan',
                      },
                    );
                  },
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CornerBracketPainter(
          color: AppColors.accentBlue,
          strokeWidth: 3.2,
          cornerLength: 28,
          radius: 16,
        ),
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLength)
        ..lineTo(rect.left, rect.top + radius)
        ..quadraticBezierTo(
          rect.left,
          rect.top,
          rect.left + radius,
          rect.top,
        )
        ..lineTo(rect.left + cornerLength, rect.top),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.top)
        ..lineTo(rect.right - radius, rect.top)
        ..quadraticBezierTo(
          rect.right,
          rect.top,
          rect.right,
          rect.top + radius,
        )
        ..lineTo(rect.right, rect.top + cornerLength),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right, rect.bottom - cornerLength)
        ..lineTo(rect.right, rect.bottom - radius)
        ..quadraticBezierTo(
          rect.right,
          rect.bottom,
          rect.right - radius,
          rect.bottom,
        )
        ..lineTo(rect.right - cornerLength, rect.bottom),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left + cornerLength, rect.bottom)
        ..lineTo(rect.left + radius, rect.bottom)
        ..quadraticBezierTo(
          rect.left,
          rect.bottom,
          rect.left,
          rect.bottom - radius,
        )
        ..lineTo(rect.left, rect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.radius != radius;
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: AppColors.accentBlue,
            width: 5,
          ),
          boxShadow: AppShadows.elevated,
        ),
        child: const Icon(
          Icons.photo_camera_rounded,
          color: AppColors.accentPurple,
          size: 30,
        ),
      ),
    );
  }
}
