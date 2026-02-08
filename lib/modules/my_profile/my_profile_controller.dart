import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart'; // ajusta si tu archivo de rutas es otro

class MyProfileController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  // Text controllers
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  // Estado
  final isLoading = false.obs;
  final isSavingProfile = false.obs;
  final isChangingPassword = false.obs;
  final isDeleting = false.obs;

  final roles = <String>[].obs;
  final selectedRole = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      isLoading.value = true;
      final sessionUser = AppStorage.getUser();
      if (sessionUser != null && sessionUser.roles.isNotEmpty) {
        roles.assignAll(sessionUser.roles);
      }

      final data = await _api.getAccount();

      // Asumiendo que data es el usuario directamente
      nameCtrl.text = data['name']?.toString() ?? '';
      emailCtrl.text = data['email']?.toString() ?? '';

      final apiRoles = (data['roles'] is List)
          ? (data['roles'] as List)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : <String>[];
      if (apiRoles.isNotEmpty) {
        roles.assignAll(apiRoles);
      }

      final role = (data['active_role'] ?? data['role'])?.toString();
      if (role != null && role.isNotEmpty) {
        if (!roles.contains(role)) {
          roles.add(role);
        }
        selectedRole.value = role;
      }

      // Opcional: sincronizar con storage local si tienes un modelo de user
      // await AppStorage.setUser(User.fromJson(data));
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final role = selectedRole.value;

    if (name.isEmpty || email.isEmpty) {
      Get.snackbar(
        'Datos incompletos',
        'Nombre y correo son obligatorios',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSavingProfile.value = true;

      final res = await _api.updateAccount(
        name: name,
        email: email,
        role: role,
      );

      // Si la API devuelve { message, user }, tomamos el user
      final userData =
          (res['user'] is Map) ? Map<String, dynamic>.from(res['user']) : res;

      final switchedRole =
          (userData['active_role'] ?? userData['role'])?.toString();
      if (switchedRole != null && switchedRole.isNotEmpty) {
        await AppStorage.setActiveRole(switchedRole);
        selectedRole.value = switchedRole;
      }

      // Si tienes un modelo User y AppStorage.setUser, puedes hacerlo aquí
      // await AppStorage.setUser(User.fromJson(userData));

      Get.snackbar(
        'Perfil actualizado',
        'Tus datos se guardaron correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSavingProfile.value = false;
    }
  }

  Future<void> changePassword() async {
    final current = currentPasswordCtrl.text;
    final newPass = newPasswordCtrl.text;
    final confirm = confirmPasswordCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      Get.snackbar(
        'Datos incompletos',
        'Llena todos los campos de contraseña.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPass != confirm) {
      Get.snackbar(
        'Contraseña',
        'La confirmación no coincide.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isChangingPassword.value = true;

      await _api.updateAccountPassword(
        currentPassword: current,
        newPassword: newPass,
        confirmPassword: confirm,
      );

      currentPasswordCtrl.clear();
      newPasswordCtrl.clear();
      confirmPasswordCtrl.clear();

      Get.snackbar(
        'Éxito',
        'Contraseña actualizada correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isChangingPassword.value = false;
    }
  }

  Future<void> confirmDeleteAccount() async {
    Get.defaultDialog(
      title: 'Eliminar cuenta',
      middleText:
          'Esta acción eliminará tu cuenta y no podrás volver a acceder con ella.\n\n¿Deseas continuar?',
      textCancel: 'Cancelar',
      textConfirm: 'Eliminar',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back(); // cerrar dialog
        deleteAccount();
      },
    );
  }

  Future<void> deleteAccount() async {
    try {
      isDeleting.value = true;

      await _api.deleteAccount();

      // limpiar storage local
      await AppStorage.clearAll();

      // limpiamos tokens de sesión llamando al logout
      // (si quieres evitar la llamada al backend, al menos limpia TokenStorage ahí)
      await _api.logout();

      // navegar al login
      Get.offAllNamed(Routes.login);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isDeleting.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }
}
