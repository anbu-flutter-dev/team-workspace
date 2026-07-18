import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:team_workspace/core/utils/log.dart';

/// Logs one block per call, built at response/error time (not request time)
/// so method, headers, body, and the response all land together instead of
/// being split across two log lines that can get interleaved with other
/// in-flight requests.
class LoggingInterceptor extends Interceptor {
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    log(
      _describe(
        response.requestOptions,
        statusCode: response.statusCode,
        body: response.data,
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log(
      _describe(
        err.requestOptions,
        statusCode: err.response?.statusCode,
        body: err.response?.data ?? err.message,
      ),
    );
    handler.next(err);
  }

  String _describe(
    RequestOptions options, {
    required int? statusCode,
    required Object? body,
  }) {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return '${options.method} | ${options.uri}\n'
        'HEADERS: ${_pretty(options.headers)}\n'
        'BODY: ${_pretty(options.data)}\n'
        '\n'
        'RESPONSE$status: ${_pretty(body)}';
  }

  String _pretty(Object? data) {
    if (data == null) return 'null';
    try {
      return _prettyEncoder.convert(data);
    } on JsonUnsupportedObjectError {
      return data.toString();
    }
  }
}
