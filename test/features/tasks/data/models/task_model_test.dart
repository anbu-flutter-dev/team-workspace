import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/tasks/data/models/task_model.dart';
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

  test('toJson serializes the nested AssignedUser, not the raw object', () {
    // Regression test: without `explicitToJson: true` on TaskModel's
    // @JsonSerializable, this field silently comes back as an
    // AssignedUserModel instance instead of a Map — compiles fine, but
    // Hive.put() then throws "Cannot write, unknown type: AssignedUserModel"
    // the first time anything gets saved.
    final json = TaskModel.fromEntity(task).toJson();
    expect(json['assignedUser'], isA<Map<String, dynamic>>());
    expect(json['assignedUser'], {'name': 'Aditi Rao'});
  });

  test('fromJson(toJson(task)) round-trips to an equal Task entity', () {
    final json = TaskModel.fromEntity(task).toJson();
    final roundTripped = TaskModel.fromJson(json).toEntity();
    expect(roundTripped, task);
  });
}
