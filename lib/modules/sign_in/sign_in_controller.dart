// lib/modules/signin/sign_in_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class SignInController extends GetxController {
  final _api = Get.find<ApiRepository>();

  late final int orgId;

  // Form
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final roles = const ['manager', 'coach', 'parent', 'player'];
  final role = RxnString();

  final isObscure = true.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;

    orgId = (args?['orgId'] as int?) ?? 2;
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
    // Validación UI
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
        role: currentRole,
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
