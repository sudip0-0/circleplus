import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/plan.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({required this.plan, super.key});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.go('/circles/${plan.circleId}/plans/${plan.id}'),
        title: Text(plan.title),
        subtitle: Text(
          [
            DateFormat.yMMMd().add_jm().format(plan.startsAt),
            if (plan.location?.isNotEmpty == true) plan.location!,
            '${plan.inCount} in, ${plan.maybeCount} maybe, ${plan.cantCount} can\'t',
          ].join('\n'),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
