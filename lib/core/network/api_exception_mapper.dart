import 'package:dio/dio.dart';
import 'package:team_workspace/core/error/exceptions.dart';

Exception mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return NetworkException();
    case DioExceptionType.badResponse:
      return ServerException('Server responded with ${e.response?.statusCode}');
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return ServerException(e.message ?? 'Unexpected network error');
  }
}
