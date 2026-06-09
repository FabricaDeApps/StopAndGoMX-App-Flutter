import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/auth/social_auth_exceptions.dart';
import 'package:stopandgo/core/auth/social_auth_result.dart';
import 'package:stopandgo/core/auth/social_auth_service.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/models/responses/login_response.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/services/app_usage_session_service.dart';
import 'package:stopandgo/core/services/clarity_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/theme/theme_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';

class LoginController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final _socialAuthService = Get.find<SocialAuthService>();

  final bool isMultiOrg = !FlavorConfig.I.isCustom;
  final selectedOrganization = Rxn<OrganizationResponse>();

  // --- Branding (logo para la vista)
  final url = RxnString();

  // Form
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  // UI state
  final isLoading = false.obs;
  final obscure = true.obs;
  bool get showAppleButton => defaultTargetPlatform == TargetPlatform.iOS;

  // Resultado (opcional para UI)
  final loginResponse = Rxn<LoginResponse>();

  @override
  void onReady() {
    super.onReady();
    _loadBrandingFromStorage();
    if (isMultiOrg && selectedOrganization.value == null) {
      Get.offAllNamed(Routes.teamSelector);
    }
  }

  String _buildLogoUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return 'https://stopandgomx.app/storage/$cleanPath';
  }

  void _loadBrandingFromStorage() {
    selectedOrganization.value = AppStorage.getOrganization();
    final logo = selectedOrganization.value?.logo ?? '';
    url.value = _buildLogoUrl(logo);
    if (isMultiOrg && selectedOrganization.value?.id != null) {
      FlavorConfig.I.updateOrganizationId(selectedOrganization.value!.id);
    }
    Get.find<ThemeController>().refreshTheme();
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Ingresa tu email';
    final hasAt = value.contains('@') && value.contains('.');
    if (!hasAt) return 'Email inválido';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> submit() async {
    if (isMultiOrg && selectedOrganization.value == null) {
      Get.snackbar(
        'Selecciona equipo',
        'Primero elige un equipo para continuar',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(Routes.teamSelector);
      return;
    }

    final current = formKey.currentState;
    if (current == null || !current.validate()) return;

    FocusScope.of(Get.context!).unfocus();

    isLoading.value = true;
    try {
      ClarityService.trackEvent('login_attempt');
      final res = await _api.login(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      loginResponse.value = res;

      try {
        final org = await _api.getOrganization();
        await AppStorage.setOrganization(org);
        Get.find<ThemeController>().refreshTheme();
      } catch (e) {
        debugPrint('⚠️ No se pudo cargar org post-login: $e');
      }

      Get.snackbar(
        'Bienvenido',
        res.user.name,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      ClarityService.setUserContext(
        userId: res.user.id,
        role: res.user.activeRole.isNotEmpty
            ? res.user.activeRole
            : res.user.role,
        organizationId: FlavorConfig.I.organizationId,
      );
      ClarityService.trackEvent('login_success');

      if (Get.isRegistered<AppUsageSessionService>()) {
        await Get.find<AppUsageSessionService>().handleAuthenticatedEntry(
          source: 'app_open',
        );
      }

      Get.offAllNamed(Routes.home);
    } catch (e) {
      ClarityService.trackEvent('login_failed');
      Get.snackbar(
        'Error de autenticación',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitGoogle() async {
    await _submitSocial(_socialAuthService.signInWithGoogle);
  }

  Future<void> submitApple() async {
    await _submitSocial(_socialAuthService.signInWithApple);
  }

  Future<void> _submitSocial(
    Future<SocialAuthResult> Function() socialLogin,
  ) async {
    if (isLoading.value) return;

    if (isMultiOrg && selectedOrganization.value == null) {
      Get.snackbar(
        'Selecciona equipo',
        'Primero elige un equipo para continuar',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(Routes.teamSelector);
      return;
    }

    FocusScope.of(Get.context!).unfocus();

    SocialAuthResult? socialAuth;
    isLoading.value = true;
    try {
      socialAuth = await socialLogin();
      final res = await _api.loginWithSocial(socialAuth: socialAuth);
      await _finishAuthenticatedFlow(
        res,
        successTitle: 'Bienvenido',
        successMessage: res.user.name,
        clarityEvent: 'login_social_success',
        source: 'social_${socialAuth.provider.apiValue}',
      );
    } on SocialAuthCancelledException {
      // El usuario canceló el flujo; no mostramos error.
    } on SocialAuthConfigurationException catch (e) {
      Get.snackbar(
        'Configuración',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on DioException catch (e) {
      final code = _extractApiCode(e);
      if (code == 'USER_NOT_FOUND' && socialAuth != null) {
        Get.toNamed(Routes.signIn, arguments: socialAuth);
        Get.snackbar(
          'Registro',
          'Tu cuenta social es válida, pero aún no existe un usuario. Completa tu registro.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        ClarityService.trackEvent('login_social_failed');
        Get.snackbar(
          'Error de autenticación',
          _extractApiMessage(e, fallback: 'No fue posible iniciar sesión.'),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      ClarityService.trackEvent('login_social_failed');
      Get.snackbar(
        'Error de autenticación',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _finishAuthenticatedFlow(
    LoginResponse res, {
    required String successTitle,
    required String successMessage,
    required String clarityEvent,
    required String source,
  }) async {
    loginResponse.value = res;

    try {
      final org = await _api.getOrganization();
      await AppStorage.setOrganization(org);
      Get.find<ThemeController>().refreshTheme();
    } catch (e) {
      debugPrint('⚠️ No se pudo cargar org post-auth: $e');
    }

    Get.snackbar(
      successTitle,
      successMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );

    ClarityService.setUserContext(
      userId: res.user.id,
      role: res.user.activeRole.isNotEmpty
          ? res.user.activeRole
          : res.user.role,
      organizationId: FlavorConfig.I.organizationId,
    );
    ClarityService.trackEvent(clarityEvent);

    if (Get.isRegistered<AppUsageSessionService>()) {
      await Get.find<AppUsageSessionService>().handleAuthenticatedEntry(
        source: source,
      );
    }

    Get.offAllNamed(Routes.home);
  }

  String _extractApiMessage(DioException error, {required String fallback}) {
    final payload = error.response?.data;
    if (payload is Map) {
      final message = (payload['message'] ?? '').toString().trim();
      if (message.isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  String _extractApiCode(DioException error) {
    final payload = error.response?.data;
    if (payload is Map) {
      return (payload['code'] ?? '').toString().trim();
    }
    return '';
  }

  /*
  Future<void> _persistSession(LoginResponse res) async {
    // 1) Tokens (en GetStorage). Si tu ApiRepository ya lo hace, no pasa nada por sobrescribir.
    await _box.write(_kAccessToken, res.accessToken);
    await _box.write(_kRefreshToken, res.refreshToken);
    await _box.write(_kTokenType, res.tokenType);
    await _box.write(_kRefreshExp, res.refreshExpiresAt);
    await _box.write(_kAccessTTLMin, res.accessExpiresInMinutes);
  }
*/

  String? validateEmailPublic(String? v) => _validateEmail(v);
  String? validatePasswordPublic(String? v) => _validatePassword(v);

  @override
  void onClose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    super.onClose();
  }
}
