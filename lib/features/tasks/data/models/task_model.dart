import 'package:json_annotation/json_annotation.dart';
import 'package:team_workspace/features/tasks/data/models/assigned_user_model.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

part 'task_model.g.dart';

/// Hive/cache persistence shape for a [Task].
///
/// explicitToJson is required here: without it, json_serializable's default
/// toJson() puts the raw AssignedUserModel object into the map instead of
/// calling .toJson() on it, which compiles fine but breaks the moment Hive
/// tries to write it (`HiveError: Cannot write, unknown type: AssignedUserModel`).
@JsonSerializable(explicitToJson: true)
class TaskModel {
  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.assignedUser,
  });

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final TaskStatus status;
  final AssignedUserModel assignedUser;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  factory TaskModel.fromEntity(Task entity) => TaskModel(
    id: entity.id,
    title: entity.title,
    description: entity.description,
    priority: entity.priority,
    dueDate: entity.dueDate,
    status: entity.status,
    assignedUser: AssignedUserModel.fromEntity(entity.assignedUser),
  );

  Task toEntity() => Task(
    id: id,
    title: title,
    description: description,
    priority: priority,
    dueDate: dueDate,
    status: status,
    assignedUser: assignedUser.toEntity(),
  );
}
