import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SignaturePadWidget extends StatefulWidget {
  final Function(List<Offset?> points) onSigned;
  final VoidCallback? onClear;

  const SignaturePadWidget({
    super.key,
    required this.onSigned,
    this.onClear,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (_points.isEmpty)
                  const Center(
                    child: Text(
                      'Sign here with finger / stylus',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) {
                    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                      setState(() {
                        _points.add(localPosition);
                      });
                      widget.onSigned(_points);
                    }
                  },
                  onPanEnd: (DragEndDetails details) {
                    _points.add(null);
                    widget.onSigned(_points);
                  },
                  child: CustomPaint(
                    painter: SignaturePainter(points: _points),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _points.clear();
                });
                widget.onSigned([]);
                if (widget.onClear != null) widget.onClear!();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF64748B)),
              label: const Text('Clear Pad', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ),
          ],
        ),
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(ui.PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => oldDelegate.points != points;
}
