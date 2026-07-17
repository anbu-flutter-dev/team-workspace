import 'package:json_annotation/json_annotation.dart';

part 'task_dto.g.dart';

/// Raw shape of a dummyjson todo — id/todo/completed/userId, nothing else.
@JsonSerializable()
class TaskDto {
  TaskDto({
    required this.id,
    required this.todo,
    required this.completed,
    required this.userId,
  });

  final int id;
  final String todo;
  final bool completed;
  final int userId;

  factory TaskDto.fromJson(Map<String, dynamic> json) =>
      _$TaskDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TaskDtoToJson(this);
}

@JsonSerializable()
class TaskListResponseDto {
  TaskListResponseDto({
    required this.todos,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<TaskDto> todos;
  final int total;
  final int skip;
  final int limit;

  factory TaskListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TaskListResponseDtoFromJson(json);
}
