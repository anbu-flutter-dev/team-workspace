import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/network/api_constants.dart';
import 'package:team_workspace/core/network/api_exception_mapper.dart';
import 'package:team_workspace/features/tasks/data/models/task_dto.dart';

abstract interface class TaskRemoteDataSource {
  Future<TaskListResponseDto> fetchTasks({required int page});

  Future<TaskDto> fetchTaskById(int id);

  /// dummyjson echoes back a fake record but never actually persists it.
  Future<void> createTask({required String todo, required bool completed});

  Future<void> updateTask(int id, {String? todo, bool? completed});
}

@LazySingleton(as: TaskRemoteDataSource)
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<TaskListResponseDto> fetchTasks({required int page}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.todos,
        queryParameters: {
          'limit': ApiConstants.pageSize,
          'skip': (page - 1) * ApiConstants.pageSize,
        },
      );
      return TaskListResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<TaskDto> fetchTaskById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.todos}/$id',
      );
      return TaskDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> createTask({
    required String todo,
    required bool completed,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.todos}/add',
        data: {'todo': todo, 'completed': completed, 'userId': 1},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> updateTask(int id, {String? todo, bool? completed}) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.todos}/$id',
        data: {
          if (todo != null) 'todo': todo,
          if (completed != null) 'completed': completed,
        },
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
