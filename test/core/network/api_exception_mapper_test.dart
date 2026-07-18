import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/core/error/exceptions.dart';
import 'package:team_workspace/core/network/api_exception_mapper.dart';

RequestOptions _options() => RequestOptions(path: '/todos');

void main() {
  test('connectionError maps to NetworkException', () {
    final error = DioException(
      requestOptions: _options(),
      type: DioExceptionType.connectionError,
    );
    expect(mapDioException(error), isA<NetworkException>());
  });

  test('unknown wrapping a SocketException maps to NetworkException', () {
    // Regression test: a genuinely offline device often surfaces here
    // instead of as connectionError — this used to be misclassified as a
    // ServerException, which skipped the cached-data fallback entirely.
    final error = DioException(
      requestOptions: _options(),
      type: DioExceptionType.unknown,
      error: const SocketException('Failed host lookup'),
    );
    expect(mapDioException(error), isA<NetworkException>());
  });

  test('unknown wrapping something else maps to ServerException', () {
    final error = DioException(
      requestOptions: _options(),
      type: DioExceptionType.unknown,
      error: StateError('boom'),
    );
    expect(mapDioException(error), isA<ServerException>());
  });

  test('badResponse maps to ServerException', () {
    final error = DioException(
      requestOptions: _options(),
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: _options(), statusCode: 500),
    );
    expect(mapDioException(error), isA<ServerException>());
  });
}
