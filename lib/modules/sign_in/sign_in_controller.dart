// lib/modules/signin/sign_in_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class SignInController extends GetxController {
  final _api = Get.find<ApiRepository>();

  late final int orgId;

  // Form
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

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
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    orgId = FlavorConfig.I.organizationId!;
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

  Future<void> submit() async {
    final currentRole = role.value;

    if (!formKey.currentState!.validate()) return;

    if (currentRole == null || currentRole.isEmpty) {
      Get.snackbar(
        'Registro',
        'Selecciona un rol',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
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
        Get.back(result: true);
        Get.snackbar(
          'Registro',
          msg.isEmpty ? 'Usuario registrado' : msg,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Registro',
          msg.isEmpty ? 'No se pudo registrar' : msg,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
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
    super.onClose();
  }
}
