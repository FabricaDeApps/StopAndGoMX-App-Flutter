import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../config/flavor_config.dart';

final _uuid = const Uuid();

class SentryInterceptor extends Interceptor {
  bool _shouldCapture(int? status) {
    if (status == null) return false;
    return status == 404 || status >= 500;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Request-Id'] ??= _uuid.v4();

    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        data: {
          'method': options.method,
          'url': options.uri.toString(),
          'path': options.path,
        },
        level: SentryLevel.info,
      ),
    );

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;

    if (_shouldCapture(status)) {
      final flavor = FlavorConfig.I.flavor.name;
      final orgId = FlavorConfig.I.organizationId;
      final reqId = err.requestOptions.headers['X-Request-Id']?.toString();

      await Sentry.captureException(
        err,
        stackTrace: err.stackTrace,
        withScope: (scope) {
          // Tags (para filtros)
          scope.setTag('flavor', flavor);
          if (orgId != null) scope.setTag('organization_id', '$orgId');
          if (reqId != null) scope.setTag('request_id', reqId);
          scope.setTag('http_status', '${status ?? 'null'}');
          scope.setTag('http_method', err.requestOptions.method);
          scope.setTag('http_path', err.requestOptions.path);

          // ✅ API NUEVA: un contexto por llamada
          scope.setContexts('request', {
            'url': err.requestOptions.uri.toString(),
            'baseUrl': err.requestOptions.baseUrl,
            'path': err.requestOptions.path,
            'query': err.requestOptions.queryParameters,
            'headers': {
              'X-Organization-Id':
                  err.requestOptions.headers['X-Organization-Id'],
              'X-Request-Id': err.requestOptions.headers['X-Request-Id'],
            },
            'data': err.requestOptions.data,
          });

          scope.setContexts('response', {
            'status': status,
            'data': err.response?.data,
          });
        },
      );
    }

    return handler.next(err);
  }

  /// 🔥 IMPORTANTE: por si Dio trata 404 como success (validateStatus)
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final status = response.statusCode;

    if (_shouldCapture(status)) {
      final flavor = FlavorConfig.I.flavor.name;
      final orgId = FlavorConfig.I.organizationId;
      final reqId = response.requestOptions.headers['X-Request-Id']?.toString();

      Sentry.captureMessage(
        'HTTP $status ${response.requestOptions.method} ${response.requestOptions.path}',
        withScope: (scope) {
          scope.setTag('flavor', flavor);
          if (orgId != null) scope.setTag('organization_id', '$orgId');
          if (reqId != null) scope.setTag('request_id', reqId);
          scope.setTag('http_status', '$status');
          scope.setTag('http_method', response.requestOptions.method);
          scope.setTag('http_path', response.requestOptions.path);

          scope.setContexts('request', {
            'url': response.requestOptions.uri.toString(),
            'query': response.requestOptions.queryParameters,
          });

          scope.setContexts('response', {'data': response.data});
        },
      );
    }

    handler.next(response);
  }
}
