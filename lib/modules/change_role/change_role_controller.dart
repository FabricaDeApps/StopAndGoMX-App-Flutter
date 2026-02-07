import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:stopandgo/routes/app_routes.dart';

class ChangeRoleController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final role = ''.obs;
  late final AnimationController pulseController;
  late final Animation<double> pulse;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['role'] != null) {
      role.value = args['role'].toString();
    }

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    pulse = CurvedAnimation(
      parent: pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void onReady() {
    super.onReady();
    _finishTransition();
  }

  Future<void> _finishTransition() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (isClosed) return;
    Get.offAllNamed(Routes.home);
  }

  @override
  void onClose() {
    pulseController.dispose();
    super.onClose();
  }

  String get roleLabel {
    switch (role.value) {
      case 'parent':
        return 'Padre/Madre';
      case 'player':
        return 'Jugador';
      case 'coach':
        return 'Entrenador';
      case 'manager':
        return 'Manager';
      case 'staff':
        return 'Personal';
      case 'admin':
        return 'Administrador';
      default:
        return role.value.isEmpty ? 'usuario' : role.value;
    }
  }
}
