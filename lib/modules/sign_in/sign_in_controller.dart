// lib/modules/signin/sign_in_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/services/clarity_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class SignInController extends GetxController {
  final _api = Get.find<ApiRepository>();

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
    'coach': 'Entrenador',
    'manager': 'Manager',
    'player': 'Jugador',
    'staff': 'Staff',
  };

  // Valor real que va al backend
  final role = RxnString();

  // Opcional: lista de roles para la UI
  List<String> get availableRoles => roleLabelsEs.keys.toList();

  // Label UI
  String roleLabel(String value) => roleLabelsEs[value] ?? value;

  final isObscure = true.obs;
  final isConfirmObscure = true.obs;
  final isLoading = false.obs;
  final teamConfirmed = false.obs;
  final organization = Rxn<OrganizationResponse>();
  bool get requiresTeamConfirmation => !FlavorConfig.I.isCustom;

  @override
  void onInit() {
    super.onInit();
    orgId = FlavorConfig.I.organizationId!;
    organization.value = AppStorage.getOrganization();
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Ingresa tu email';
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!re.hasMatch(value)) return 'Email inválido';
    return null;
  }

  String? _validateNotEmpty(String? v, String field) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Ingresa $field';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v?.trim() ?? '';
    if (value.length < 8)
      return 'La contraseña debe tener al menos 8 caracteres';
    return null;
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
      ClarityService.trackEvent('signup_attempt');
      final resp = await _api.registerPublicUser(
        organizationId: orgId,
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        role: currentRole, // ✅ aquí va parent/coach/etc.
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
    } catch (e) {
      ClarityService.trackEvent('signup_failed');
      Get.snackbar(
        'Registro',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
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
