import 'package:flutter/material.dart';

import '../../data/models/job/job_model.dart';
import '../../utils/helpers.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.statusColor,
    required this.priorityColor,
    required this.onTap,
    this.distanceMeters,
  });

  final JobModel job;
  final Color statusColor;
  final Color priorityColor;
  final VoidCallback onTap;

  /// When non-null, shows a distance chip at the bottom of the card.
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final isHotJob = job.status == JobStatus.unassigned && job.priority == JobPriority.high;
    final isOverdue = job.isOverdue == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Container(
        decoration: isOverdue || isHotJob
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    isOverdue
                        ? Colors.red.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (isOverdue) ...[
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                            const SizedBox(width: 6),
                          ] else if (isHotJob) ...[
                            const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 20),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              job.title ?? 'No Title',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (job.price != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${job.currency ?? '\$'} ${job.price!.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                        ),
                      ),
                    JobStatusChip(label: job.priority?.name ?? 'Unknown', color: priorityColor),
                  ],
                ),
                const SizedBox(height: 8),
                if (job.description != null)
                  Text(
                    job.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                if (job.customerName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        job.customerName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isOverdue)
                      const JobStatusChip(label: 'OVERDUE', color: Colors.red)
                    else
                      JobStatusChip(label: job.status?.name ?? 'Unknown', color: statusColor),
                    const Spacer(),
                    if (distanceMeters != null) _DistanceChip(meters: distanceMeters!),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.meters});
  final double meters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            AppHelpers.formatDistance(meters),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class JobStatusChip extends StatelessWidget {
  const JobStatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
