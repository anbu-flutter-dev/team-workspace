import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_page.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';

@injectable
class GetTasksUseCase {
  GetTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<Result<TaskPage>> call({required int page}) =>
      _repository.getTasks(page: page);
}
