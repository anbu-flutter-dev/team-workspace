import 'package:flutter/material.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final TaskStatus status;

  Color _color(BuildContext context) => switch (status) {
    TaskStatus.pending => Colors.grey.shade600,
    TaskStatus.inProgress => Theme.of(context).colorScheme.primary,
    TaskStatus.completed => Colors.green.shade700,
  };

  String get _label => switch (status) {
    TaskStatus.pending => 'Pending',
    TaskStatus.inProgress => 'In progress',
    TaskStatus.completed => 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
