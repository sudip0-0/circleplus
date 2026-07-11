import 'package:flutter/material.dart';

class PlanCancelledBanner extends StatelessWidget {
  const PlanCancelledBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            'This plan has been cancelled.',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
