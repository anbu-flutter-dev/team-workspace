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
      return ServerException(e.message ?? 'Unexpected network error');
    case DioExceptionType.unknown:
      // A genuinely offline device (DNS failure, connection refused) often
      // surfaces here wrapping a SocketException rather than as
      // connectionError. Checked by type name instead of `is SocketException`
      // so this file stays importable on web, where dart:io isn't available.
      if (e.error?.runtimeType.toString().contains('SocketException') ??
          false) {
        return NetworkException();
      }
      return ServerException(e.message ?? 'Unexpected network error');
  }
}
