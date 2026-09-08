import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/theme.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final Color? color;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat('#,##,##0.00', 'en_IN').format(amount);
    final textStyle = style ?? AppTextStyles.bodyLargeNumeric;

    return Text(
      '₹ $formatted',
      style: color != null ? textStyle.copyWith(color: color) : textStyle,
    );
  }
}
