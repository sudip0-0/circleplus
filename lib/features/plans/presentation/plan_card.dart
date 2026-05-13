import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/circlepulse_ui.dart';
import '../domain/plan.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({required this.plan, super.key});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WarmCard(
        onTap: () => context.push('/circles/${plan.circleId}/plans/${plan.id}'),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: CirclePulseColors.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.event_available_outlined,
                color: CirclePulseColors.clay,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat.yMMMd().add_jm().format(plan.startsAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CirclePulseColors.muted,
                    ),
                  ),
                  Text(
                    '${plan.inCount} in, ${plan.maybeCount} maybe, ${plan.cantCount} can\'t',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
