import 'package:flutter/material.dart';
import 'package:team_workspace/core/theme/app_colors.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';

class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority});

  final TaskPriority priority;

  Color get _color => switch (priority) {
    TaskPriority.low => AppColors.priorityLow,
    TaskPriority.medium => AppColors.priorityMedium,
    TaskPriority.high => AppColors.priorityHigh,
  };

  String get _label => switch (priority) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
