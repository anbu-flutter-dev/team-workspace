import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/di/injection.dart';
import 'package:team_workspace/core/utils/date_formatter.dart';
import 'package:team_workspace/core/utils/validators.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_state.dart';

/// Shared by create and edit — pass `initialTask` to switch into edit mode
/// (pre-populated fields plus a status picker).
class TaskFormView extends StatelessWidget {
  const TaskFormView({super.key, this.initialTask});

  final Task? initialTask;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskFormBloc>(),
      child: _TaskFormBody(initialTask: initialTask),
    );
  }
}

class _TaskFormBody extends StatefulWidget {
  const _TaskFormBody({this.initialTask});

  final Task? initialTask;

  @override
  State<_TaskFormBody> createState() => _TaskFormBodyState();
}

class _TaskFormBodyState extends State<_TaskFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  late TaskStatus _status;
  late DateTime _dueDate;

  bool get _isEditMode => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.pending;
    _dueDate = task?.dueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDueDate() async {
    final today = _startOfToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(today) ? today : _dueDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  String? _validateDueDate(DateTime? _) {
    if (_dueDate.isBefore(_startOfToday())) {
      return 'Due date must be today or later';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<TaskFormBloc>().add(
      TaskFormSubmitted(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        status: _isEditMode ? _status : null,
        existingTask: widget.initialTask,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit task' : 'New task')),
      body: BlocListener<TaskFormBloc, TaskFormState>(
        listener: (context, state) {
          if (state is TaskFormSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEditMode ? 'Task updated' : 'Task created'),
              ),
            );
            context.pop();
          } else if (state is TaskFormSubmitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                action: SnackBarAction(label: 'Retry', onPressed: _submit),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => Validators.required(
                    value,
                    fieldName: 'Title',
                    maxLength: 100,
                  ),
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Description'),
                ),
                const SizedBox(height: 16),
                Text('Priority', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<TaskPriority>(
                  segments: const [
                    ButtonSegment(
                      value: TaskPriority.low,
                      label: Text('Low', style: TextStyle(fontSize: 13)),
                    ),
                    ButtonSegment(
                      value: TaskPriority.medium,
                      label: Text('Medium', style: TextStyle(fontSize: 13)),
                    ),
                    ButtonSegment(
                      value: TaskPriority.high,
                      label: Text('High', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (selection) =>
                      setState(() => _priority = selection.first),
                ),
                if (_isEditMode) ...[
                  const SizedBox(height: 16),
                  Text('Status', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<TaskStatus>(
                    segments: const [
                      ButtonSegment(
                        value: TaskStatus.pending,
                        label: Text('Pending', style: TextStyle(fontSize: 13)),
                      ),
                      ButtonSegment(
                        value: TaskStatus.inProgress,
                        label: Text(
                          'In progress',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      ButtonSegment(
                        value: TaskStatus.completed,
                        label: Text(
                          'Completed',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    selected: {_status},
                    onSelectionChanged: (selection) =>
                        setState(() => _status = selection.first),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Due date', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                FormField<DateTime>(
                  initialValue: _dueDate,
                  validator: _validateDueDate,
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickDueDate,
                          icon: const Icon(Icons.event),
                          label: Text(DateFormatter.dueDate(_dueDate)),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                BlocBuilder<TaskFormBloc, TaskFormState>(
                  builder: (context, state) {
                    final isSubmitting = state is TaskFormSubmitting;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEditMode ? 'Save changes' : 'Create task',
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
