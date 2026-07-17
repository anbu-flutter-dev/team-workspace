import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/di/injection.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_detail_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_detail_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_detail_state.dart';
import 'package:team_workspace/features/tasks/presentation/widgets/task_form_view.dart';

/// Fetches the task via TaskDetailBloc (already has loading/success/failure
/// states) and hands it to the shared form once loaded.
class EditTaskPage extends StatelessWidget {
  const EditTaskPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskDetailBloc>()..add(TaskDetailStarted(taskId)),
      child: BlocBuilder<TaskDetailBloc, TaskDetailState>(
        builder: (context, state) {
          return switch (state) {
            TaskDetailLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            TaskDetailLoadFailure(:final message) => Scaffold(
              appBar: AppBar(title: const Text('Edit task')),
              body: Center(child: Text(message)),
            ),
            TaskDetailToggleFailed(:final revertedTask) => TaskFormView(
              initialTask: revertedTask,
            ),
            TaskDetailLoadSuccess(:final task) => TaskFormView(
              initialTask: task,
            ),
          };
        },
      ),
    );
  }
}
