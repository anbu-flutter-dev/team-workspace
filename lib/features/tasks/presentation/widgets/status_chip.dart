import 'package:flutter/material.dart';
import 'package:team_workspace/core/theme/app_colors.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final TaskStatus status;

  Color get _color => switch (status) {
    TaskStatus.pending => AppColors.statusPending,
    TaskStatus.inProgress => AppColors.statusInProgress,
    TaskStatus.completed => AppColors.statusCompleted,
  };

  IconData get _icon => switch (status) {
    TaskStatus.pending => Icons.schedule_rounded,
    TaskStatus.inProgress => Icons.autorenew_rounded,
    TaskStatus.completed => Icons.check_circle_rounded,
  };

  String get _label => switch (status) {
    TaskStatus.pending => 'Pending',
    TaskStatus.inProgress => 'In progress',
    TaskStatus.completed => 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: _color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
