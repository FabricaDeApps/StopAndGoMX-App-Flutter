// lib/modules/signin/sign_in_controller.dart
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

class SignInController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final _socialAuthService = Get.find<SocialAuthService>();

  late final int orgId;

  // Form
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  // 👇 Debe ser static const (o final) para que compile bien
  static const Map<String, String> roleLabelsEs = {
    'parent': 'Padre',
    'coach': 'Coach',
    'manager': 'Manager',
    'player': 'Jugador',
    'staff': 'Staff',
  };

  static const List<String> socialAllowedRoles = <String>[
    'manager',
    'coach',
    'parent',
    'player',
  ];

  // Valor real que va al backend
  final role = RxnString();

  // Opcional: lista de roles para la UI
  List<String> get availableRoles =>
      isSocialMode ? socialAllowedRoles : roleLabelsEs.keys.toList();

  // Label UI
  String roleLabel(String value) => roleLabelsEs[value] ?? value;

  final isObscure = true.obs;
  final isConfirmObscure = true.obs;
  final isLoading = false.obs;
  final teamConfirmed = false.obs;
  final privacyAccepted = false.obs;
  final organization = Rxn<OrganizationResponse>();
  final socialAuth = Rxn<SocialAuthResult>();
  bool get requiresTeamConfirmation => !FlavorConfig.I.isCustom;
  bool get showAppleButton => defaultTargetPlatform == TargetPlatform.iOS;
  bool get isSocialMode => socialAuth.value != null;
  String get socialEmail => socialAuth.value?.email.trim() ?? '';
  String get socialProviderLabel => switch (socialAuth.value?.provider) {
    SocialAuthProvider.apple => 'Apple',
    SocialAuthProvider.google => 'Google',
    null => '',
  };

  @override
  void onInit() {
    super.onInit();
    orgId = FlavorConfig.I.organizationId!;
    organization.value = AppStorage.getOrganization();
    final args = Get.arguments;
    if (args is SocialAuthResult) {
      _applySocialAuth(args);
    }
  }

  String? validateConfirmPassword(String? v) {
    final confirm = v?.trim() ?? '';
    if (confirm.isEmpty) return 'Confirma tu contraseña';
    if (confirm != passCtrl.text.trim()) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  String get organizationName {
    final org = organization.value;
    if (org == null) return 'Tu organización';
    return org.name;
  }

  String get organizationLogoUrl {
    final raw = organization.value?.logo.trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    final cleanPath = raw.startsWith('/') ? raw.substring(1) : raw;
    return 'https://stopandgomx.app/storage/$cleanPath';
  }

  String get privacyPolicyUrl {
    final slug = organization.value?.slug.trim() ?? '';
    if (slug.isEmpty) return '';
    return 'https://$slug.stopandgomx.app/privacy-policy';
  }

  bool ensurePrivacyAccepted() {
    if (privacyAccepted.value) return true;

    Get.snackbar(
      'Registro',
      'Debes aceptar las políticas de privacidad para continuar',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  Future<void> submit() async {
    final currentRole = role.value;

    if (!formKey.currentState!.validate()) return;

    if (requiresTeamConfirmation && !teamConfirmed.value) {
      Get.snackbar(
        'Registro',
        'Confirma que este es tu equipo antes de continuar',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!ensurePrivacyAccepted()) return;

    if (currentRole == null || currentRole.isEmpty) {
      Get.snackbar(
        'Registro',
        'Selecciona un rol',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (requiresTeamConfirmation) {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar equipo'),
          content: Text(
            'Vas a crear tu cuenta para "$organizationName". ¿Es correcto?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Sí, continuar'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    isLoading.value = true;
    try {
      ClarityService.trackEvent(
        isSocialMode ? 'signup_social_attempt' : 'signup_attempt',
      );
      if (isSocialMode) {
        final res = await _api.registerPublicUserWithSocial(
          organizationId: orgId,
          socialAuth: socialAuth.value!,
          name: nameCtrl.text.trim(),
          role: currentRole,
          activeRole: currentRole,
        );
        await _finishAuthenticatedFlow(
          res,
          clarityEvent: 'signup_social_success',
          source: 'social_register_${socialAuth.value!.provider.apiValue}',
        );
      } else {
        final resp = await _api.registerPublicUser(
          organizationId: orgId,
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
          role: currentRole,
        );

        final success = resp['success'] == true;
        final msg = (resp['message'] ?? 'Operación realizada').toString();

        if (success) {
          ClarityService.trackEvent('signup_success');
          Get.back(result: true);
          Get.snackbar(
            'Registro',
            msg.isEmpty ? 'Usuario registrado' : msg,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          ClarityService.trackEvent('signup_failed');
          Get.snackbar(
            'Registro',
            msg.isEmpty ? 'No se pudo registrar' : msg,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } on SocialAuthCancelledException {
      // El usuario canceló el flujo.
    } on SocialAuthConfigurationException catch (e) {
      Get.snackbar(
        'Configuración',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on DioException catch (e) {
      ClarityService.trackEvent(
        isSocialMode ? 'signup_social_failed' : 'signup_failed',
      );
      Get.snackbar(
        'Registro',
        _extractApiMessage(e, fallback: 'No se pudo completar el registro.'),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      ClarityService.trackEvent(
        isSocialMode ? 'signup_social_failed' : 'signup_failed',
      );
      Get.snackbar(
        'Registro',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitGoogle() async {
    await _startSocialFlow(_socialAuthService.signInWithGoogle);
  }

  Future<void> submitApple() async {
    await _startSocialFlow(_socialAuthService.signInWithApple);
  }

  void clearSocialMode() {
    socialAuth.value = null;
  }

  Future<void> _startSocialFlow(
    Future<SocialAuthResult> Function() socialLogin,
  ) async {
    if (isLoading.value) return;
    if (!ensurePrivacyAccepted()) return;

    isLoading.value = true;
    try {
      final result = await socialLogin();
      _applySocialAuth(result);
      await Get.dialog<void>(
        AlertDialog(
          title: const Text('Registro'),
          content: Text(
            'Continuaremos con $socialProviderLabel. Confirma tus datos y el rol para completar el alta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back<void>(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
        barrierDismissible: true,
      );
    } on SocialAuthCancelledException {
      // El usuario canceló el flujo.
    } on SocialAuthConfigurationException catch (e) {
      Get.snackbar(
        'Configuración',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _applySocialAuth(SocialAuthResult result) {
    socialAuth.value = result;
    if (role.value != null && !socialAllowedRoles.contains(role.value)) {
      role.value = null;
    }
    if (result.email.trim().isNotEmpty) {
      emailCtrl.text = result.email.trim();
    }
    if (nameCtrl.text.trim().isEmpty && result.displayName.trim().isNotEmpty) {
      nameCtrl.text = result.displayName.trim();
    }
  }

  Future<void> _finishAuthenticatedFlow(
    LoginResponse res, {
    required String clarityEvent,
    required String source,
  }) async {
    await AppStorage.setOrganization(res.organization);
    Get.find<ThemeController>().refreshTheme();

    try {
      final org = await _api.getOrganization();
      await AppStorage.setOrganization(org);
      Get.find<ThemeController>().refreshTheme();
    } catch (_) {
      // Si falla el fetch, la sesión principal ya quedó persistida.
    }

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

    Get.snackbar(
      'Registro',
      'Tu cuenta quedó lista. Bienvenido ${res.user.name}.',
      snackPosition: SnackPosition.BOTTOM,
    );
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

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.onClose();
  }
}
