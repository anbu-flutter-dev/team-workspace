import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/di/injection.dart';
import 'package:team_workspace/core/router/app_routes.dart';
import 'package:team_workspace/core/utils/date_formatter.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_detail_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_detail_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_detail_state.dart';
import 'package:team_workspace/features/tasks/presentation/widgets/priority_chip.dart';
import 'package:team_workspace/features/tasks/presentation/widgets/status_chip.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskDetailBloc>()..add(TaskDetailStarted(taskId)),
      child: const _TaskDetailView(),
    );
  }
}

class _TaskDetailView extends StatelessWidget {
  const _TaskDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          BlocBuilder<TaskDetailBloc, TaskDetailState>(
            builder: (context, state) {
              if (state is! TaskDetailLoadSuccess) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    context.push(AppRoutes.editTaskPath(state.task.id)),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<TaskDetailBloc, TaskDetailState>(
        listenWhen: (previous, current) => current is TaskDetailToggleFailed,
        listener: (context, state) {
          if (state is TaskDetailToggleFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            TaskDetailLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TaskDetailLoadFailure(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(message),
              ),
            ),
            TaskDetailToggleFailed(:final revertedTask) => _TaskDetailBody(
              task: revertedTask,
            ),
            TaskDetailLoadSuccess(:final task) => _TaskDetailBody(task: task),
          };
        },
      ),
    );
  }
}

class _TaskDetailBody extends StatelessWidget {
  const _TaskDetailBody({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              PriorityChip(priority: task.priority),
              const SizedBox(width: 8),
              StatusChip(status: task.status),
            ],
          ),
          const SizedBox(height: 20),
          Text('Description', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(task.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          _DetailRow(
            icon: Icons.event,
            label: 'Due date',
            value: DateFormatter.dueDate(task.dueDate),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(radius: 16, child: Text(task.assignedUser.initial)),
              const SizedBox(width: 12),
              Text(
                task.assignedUser.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<TaskDetailBloc>().add(
                const TaskDetailToggleStatusRequested(),
              ),
              child: Text(
                task.isCompleted ? 'Reopen task' : 'Mark as completed',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
