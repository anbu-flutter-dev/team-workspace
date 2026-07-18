import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

void main() {
  final task = Task(
    id: '1',
    title: 'Buy groceries',
    description: 'Milk, eggs, bread',
    priority: TaskPriority.medium,
    dueDate: DateTime(2026, 1, 1),
    status: TaskStatus.pending,
    assignedUser: const AssignedUser(name: 'Aditi Rao'),
  );

  test('isCompleted is true only for TaskStatus.completed', () {
    expect(task.isCompleted, isFalse);
    expect(task.copyWith(status: TaskStatus.completed).isCompleted, isTrue);
  });

  test('isLocalOnly is true only for ids created on-device', () {
    expect(task.isLocalOnly, isFalse);
    expect(task.copyWith(id: 'local_123').isLocalOnly, isTrue);
  });

  test('copyWith overrides only the given fields', () {
    final updated = task.copyWith(title: 'Buy oat milk');
    expect(updated.title, 'Buy oat milk');
    expect(updated.id, task.id);
    expect(updated.description, task.description);
  });

  test('two tasks with the same field values are equal', () {
    final other = Task(
      id: '1',
      title: 'Buy groceries',
      description: 'Milk, eggs, bread',
      priority: TaskPriority.medium,
      dueDate: DateTime(2026, 1, 1),
      status: TaskStatus.pending,
      assignedUser: const AssignedUser(name: 'Aditi Rao'),
    );
    expect(task, other);
  });
}
