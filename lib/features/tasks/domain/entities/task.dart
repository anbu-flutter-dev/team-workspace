import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

part 'task.g.dart';

/// A task on the dashboard — enriched client-side from dummyjson's bare todo shape.
///
/// explicitToJson is required here: without it, json_serializable's default
/// toJson() puts the raw AssignedUser object into the map instead of calling
/// .toJson() on it, which compiles fine but breaks the moment Hive tries to
/// write it (`HiveError: Cannot write, unknown type: AssignedUser`).
@JsonSerializable(explicitToJson: true)
class Task extends Equatable {
  const Task({
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
  final AssignedUser assignedUser;

  bool get isCompleted => status == TaskStatus.completed;

  bool get isLocalOnly => id.startsWith('local_');

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    TaskStatus? status,
    AssignedUser? assignedUser,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      assignedUser: assignedUser ?? this.assignedUser,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    dueDate,
    status,
    assignedUser,
  ];
}
