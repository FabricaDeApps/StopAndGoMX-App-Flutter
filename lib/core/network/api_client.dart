import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_env.dart';
import 'package:stopandgo/core/network/auth_repository.dart';
import 'package:stopandgo/core/network/interceptors/sentry_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/org_interceptor.dart';
import 'token_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiClient {
  static late Dio dio;

  static Future<void> init() async {
    // Inicializa storage de tokens UNA sola vez
    if (!Get.isRegistered<TokenStorage>()) {
      await Get.putAsync<TokenStorage>(() async => TokenStorage().init());
    }

    final baseUrl = ApiEnv.baseUrl;

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );

    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(AuthRepository(), permanent: true);
    }

    // Orden IMPORTANTE:
    dio.interceptors.addAll([
      OrgInterceptor(),
      AuthInterceptor(),
      if (kReleaseMode) SentryInterceptor(),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        compact: true,
      ),
    ]);

    // Exponer Dio globalmente
    if (!Get.isRegistered<Dio>()) {
      Get.put<Dio>(dio, permanent: true);
    }
  }
}
