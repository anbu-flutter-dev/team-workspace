import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/di/hive_boxes.dart';
import 'package:team_workspace/core/network/api_constants.dart';
import 'package:team_workspace/core/network/logging_interceptor.dart';

/// Anything that isn't annotated with @injectable itself (third-party types,
/// opened Hive boxes) gets registered here instead.
@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }
    return dio;
  }

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @preResolve
  @Named(HiveBoxes.taskOverlay)
  Future<Box<dynamic>> get taskOverlayBox =>
      Hive.openBox(HiveBoxes.taskOverlay);

  @preResolve
  @Named(HiveBoxes.taskCache)
  Future<Box<dynamic>> get taskCacheBox => Hive.openBox(HiveBoxes.taskCache);

  @preResolve
  @Named(HiveBoxes.writeQueue)
  Future<Box<dynamic>> get writeQueueBox => Hive.openBox(HiveBoxes.writeQueue);
}
