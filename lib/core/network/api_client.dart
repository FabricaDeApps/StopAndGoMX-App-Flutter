import 'package:dio/dio.dart';
import 'package:get/get.dart';
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

    const baseUrl = 'https://stopandgomx.app/api';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );

    // Orden IMPORTANTE:
    dio.interceptors.addAll([
      OrgInterceptor(),
      AuthInterceptor(),
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
