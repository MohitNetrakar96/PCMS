import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  final bool isLarge;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;
    String display = label ?? status;

    final lower = status.toLowerCase();
    if (lower == 'collected' || lower == 'matched' || lower == 'active' || lower == 'verified' || lower == 'resolved' || lower == 'ok') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF14532D);
      border = const Color(0xFF86EFAC);
    } else if (lower == 'pending' || lower == 'difference_requires_approval' || lower == 'submitted') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
      border = const Color(0xFFFDE68A);
    } else if (lower == 'mismatch' || lower == 'shortfall' || lower == 'closed' || lower == 'failed') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFF991B1B);
      border = const Color(0xFFFCA5A5);
    } else if (lower == 'matured' || lower == 'cashier_accepted') {
      bg = const Color(0xFFFDFBF7);
      text = const Color(0xFF522D13);
      border = const Color(0xFFD4AF37);
    } else {
      bg = const Color(0xFFEFE7D8);
      text = const Color(0xFF6B4B32);
      border = const Color(0xFFD5C6AF);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 10 : 7, vertical: isLarge ? 4 : 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isLarge ? 8 : 6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        display.toUpperCase(),
        style: TextStyle(
          fontSize: isLarge ? 11 : 9.5,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
