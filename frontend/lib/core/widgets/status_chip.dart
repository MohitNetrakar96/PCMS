import 'package:flutter/material.dart';
import '../theme/theme.dart';

class StatusChip extends StatelessWidget {
  final CollectionStatus status;
  final bool showIcon;

  const StatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = context.appColors.statusChip(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: style.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && style.icon != null) ...[
            Icon(style.icon, size: 12, color: style.foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            style.label,
            style: AppTextStyles.labelSmall.copyWith(color: style.foregroundColor),
          ),
        ],
      ),
    );
  }
}
