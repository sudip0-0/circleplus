import 'package:flutter/material.dart';

import '../../../../shared/widgets/circlepulse_ui.dart';

class PlanCancelledBanner extends StatelessWidget {
  const PlanCancelledBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: scheme.error, size: 20),
          const SizedBox(width: 8),
          Text(
            'This plan has been cancelled.',
            style: TextStyle(
              color: CirclePulseColors.cocoa,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
