import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:team_workspace/core/di/hive_boxes.dart';
import 'package:team_workspace/core/network/api_constants.dart';
import 'package:team_workspace/core/network/logging_interceptor.dart';
import 'package:team_workspace/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:team_workspace/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:team_workspace/features/auth/domain/repositories/auth_repository.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/tasks/data/local/pending_sync_store.dart';
import 'package:team_workspace/features/tasks/data/local/task_cache_store.dart';
import 'package:team_workspace/features/tasks/data/local/task_overlay_store.dart';
import 'package:team_workspace/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:team_workspace/features/tasks/domain/usecases/get_task_by_id_usecase.dart';
import 'package:team_workspace/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_detail_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  _registerExternalDependencies();
  await _registerHiveBoxes();
  _registerAuthFeature();
  _registerTasksFeature();
}

void _registerExternalDependencies() {
  getIt
    ..registerLazySingleton<Dio>(_buildDio)
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<Connectivity>(Connectivity.new);
}

Dio _buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  if (kDebugMode) dio.interceptors.add(LoggingInterceptor());
  return dio;
}

Future<void> _registerHiveBoxes() async {
  final overlayBox = await Hive.openBox(HiveBoxes.taskOverlay);
  final cacheBox = await Hive.openBox(HiveBoxes.taskCache);
  final queueBox = await Hive.openBox(HiveBoxes.writeQueue);

  getIt
    ..registerLazySingleton(() => TaskOverlayStore(overlayBox))
    ..registerLazySingleton(() => TaskCacheStore(cacheBox))
    ..registerLazySingleton(() => PendingSyncStore(queueBox));
}

void _registerAuthFeature() {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => FirebaseAuthDataSource(getIt()),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerFactory(() => SignInUseCase(getIt()))
    ..registerFactory(() => SignUpUseCase(getIt()))
    ..registerFactory(() => SignOutUseCase(getIt()))
    ..registerLazySingleton(() => AuthBloc(getIt(), getIt(), getIt(), getIt()));
}

void _registerTasksFeature() {
  getIt
    ..registerLazySingleton<TaskRemoteDataSource>(
      () => TaskRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(getIt(), getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => GetTasksUseCase(getIt()))
    ..registerFactory(() => GetTaskByIdUseCase(getIt()))
    ..registerFactory(() => CreateTaskUseCase(getIt()))
    ..registerFactory(() => UpdateTaskUseCase(getIt()))
    ..registerFactory(() => TaskListBloc(getIt(), getIt()))
    ..registerFactory(() => TaskDetailBloc(getIt(), getIt(), getIt()))
    ..registerFactory(() => TaskFormBloc(getIt(), getIt()));
}
