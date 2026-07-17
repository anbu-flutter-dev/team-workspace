import 'package:team_workspace/features/tasks/data/models/task_dto.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/task_enrichment.dart';

extension TaskDtoMapper on TaskDto {
  Task toEntity() {
    return Task(
      id: id.toString(),
      title: todo,
      description: TaskEnrichment.descriptionFor(id, todo),
      priority: TaskEnrichment.priorityFor(id),
      dueDate: TaskEnrichment.dueDateFor(id),
      status: TaskEnrichment.initialStatusFor(id, completed: completed),
      assignedUser: TaskEnrichment.assignedUserFor(id),
    );
  }
}
