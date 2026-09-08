import 'package:flutter/material.dart';
import 'dart:math' as math;

class Banking3dVisualBanner extends StatefulWidget {
  final String title;
  final String subtitle;
  const Banking3dVisualBanner({super.key, required this.title, required this.subtitle});

  @override
  State<Banking3dVisualBanner> createState() => _Banking3dVisualBannerState();
}

class _Banking3dVisualBannerState extends State<Banking3dVisualBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF55356E),
            Color(0xFF2C153B),
            Color(0xFF191308),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF55356E).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFD6F5FF).withOpacity(0.3), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _Vault3dPainter(_controller.value),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF76A787).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF76A787), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.security, size: 12, color: Color(0xFFD6F5FF)),
                            SizedBox(width: 4),
                            Text(
                              '3D QUANTUM VAULT',
                              style: TextStyle(
                                color: Color(0xFFD6F5FF),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: const Color(0xFFE9E2F3).withOpacity(0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD6F5FF), Color(0xFF76A787)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF76A787).withOpacity(0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance, color: Color(0xFF191308), size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Vault3dPainter extends CustomPainter {
  final double progress;
  _Vault3dPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width * 0.85, size.height * 0.5);
    final angle = progress * 2 * math.pi;

    paint.color = const Color(0xFFD6F5FF).withOpacity(0.25);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 90 * math.cos(angle).abs() + 20, height: 90),
      paint,
    );

    paint.color = const Color(0xFF76A787).withOpacity(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 70, height: 70 * math.sin(angle).abs() + 15),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _Vault3dPainter oldDelegate) => oldDelegate.progress != progress;
}
