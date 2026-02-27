import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/constants/api_endpoints.dart';
import 'package:stopandgo/core/network/api_client.dart';
import 'package:stopandgo/core/network/api_request_exception.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final emailFocus = FocusNode();

  final isLoading = false.obs;
  final isSuccess = false.obs;
  final successMessage = ''.obs;
  final errorMessage = RxnString();
  bool get hasSuccess => isSuccess.value;

  DateTime? _lastSubmitAt;
  static const _debounce = Duration(milliseconds: 900);

  String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Ingresa tu correo';
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!re.hasMatch(email)) return 'Correo inválido';
    return null;
  }

  bool _isDebounced() {
    if (_lastSubmitAt == null) return false;
    return DateTime.now().difference(_lastSubmitAt!) < _debounce;
  }

  Future<void> submit() async {
    if (isLoading.value || _isDebounced()) return;
    _lastSubmitAt = DateTime.now();

    final currentForm = formKey.currentState;
    if (currentForm == null) {
      final err = validateEmail(emailCtrl.text);
      if (err != null) {
        errorMessage.value = err;
        return;
      }
    } else if (!currentForm.validate()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = null;
    isLoading.value = true;

    try {
      final res = await _dio.post(
        ApiEndpoints.authPasswordForgot,
        data: {
          'email': emailCtrl.text.trim(),
          if (FlavorConfig.I.organizationId != null)
            'organization_id': FlavorConfig.I.organizationId,
        },
        options: Options(
          headers: const {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = res.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString().trim()
          : '';
      successMessage.value = message.isNotEmpty
          ? message
          : 'Si el correo existe, enviaremos un enlace para restablecer la contraseña.';

      if (kDebugMode) {
        debugPrint(
          '[Auth] forgot_password status=${res.statusCode} organizationId=${FlavorConfig.I.organizationId ?? 'none'}',
        );
      }
      isSuccess.value = true;
    } on DioException catch (e) {
      errorMessage.value = _mapDioError(e);
    } catch (_) {
      errorMessage.value = 'Ocurrió un error inesperado. Intenta nuevamente.';
    } finally {
      isLoading.value = false;
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La solicitud tardó demasiado. Intenta nuevamente.';
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return 'No hay conexión a internet. Revisa tu red e inténtalo de nuevo.';
      case DioExceptionType.badResponse:
        final parsed = ApiRequestException.fromDio(
          e,
          fallbackMessage: 'No se pudo procesar la solicitud.',
        );
        final emailErrors = parsed.fieldErrors['email'];
        if (emailErrors != null && emailErrors.isNotEmpty) {
          return emailErrors.first;
        }
        return parsed.message;
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return 'No se pudo completar la solicitud. Intenta de nuevo.';
    }
  }

  void backToLogin() {
    Get.back<void>();
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    emailFocus.dispose();
    super.onClose();
  }
}
