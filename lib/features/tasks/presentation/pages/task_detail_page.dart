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
        title: const Text('Task details'),
        actions: [
          BlocBuilder<TaskDetailBloc, TaskDetailState>(
            builder: (context, state) {
              if (state is! TaskDetailLoadSuccess) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit task',
                onPressed: () =>
                    context.push(AppRoutes.editTaskPath(state.task.id)),
              );
            },
          ),
          const SizedBox(width: 4),
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
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PriorityChip(priority: task.priority),
              StatusChip(status: task.status),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Due date',
                    value: DateFormatter.dueDate(task.dueDate),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Assigned to: ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          task.assignedUser.initial,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.assignedUser.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.read<TaskDetailBloc>().add(
                const TaskDetailToggleStatusRequested(),
              ),
              icon: Icon(
                task.isCompleted ? Icons.replay_rounded : Icons.check_rounded,
              ),
              label: Text(
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
