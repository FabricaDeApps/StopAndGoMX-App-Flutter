import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/modules/forgot_password/forgot_password_controller.dart';

class _FakeSuccessDio extends Fake implements Dio {
  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data:
          {
                'message':
                    'Si el correo existe, enviaremos un enlace para restablecer la contraseña.',
              }
              as T,
    );
  }
}

class _FakeErrorDio extends Fake implements Dio {
  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    throw DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.init(
    flavor: AppFlavor.main,
    appName: 'Test',
    bundleId: 'com.stopandgo.test',
  );

  test('submit cambia a success cuando el repository responde OK', () async {
    final controller = ForgotPasswordController(dio: _FakeSuccessDio());

    controller.emailCtrl.text = 'usuario@dominio.com';
    await controller.submit();

    expect(controller.hasSuccess, isTrue);
    expect(controller.successMessage.value, contains('Si el correo existe'));

    controller.onClose();
  });

  test('submit cambia a error cuando el repository falla por red', () async {
    final controller = ForgotPasswordController(dio: _FakeErrorDio());

    controller.emailCtrl.text = 'usuario@dominio.com';
    await controller.submit();

    expect(controller.hasSuccess, isFalse);
    expect(controller.errorMessage.value, contains('No hay conexión'));

    controller.onClose();
  });
}
