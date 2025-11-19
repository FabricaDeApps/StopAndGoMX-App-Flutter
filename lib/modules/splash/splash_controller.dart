import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/theme/theme_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/storage/app_storage.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';

class SplashController extends GetxController {
  final _api = Get.find<ApiRepository>();

  // Estado UI
  final isLoading = true.obs;
  final error = RxnString();
  final imageUrl = RxnString();
  final primaryColor = const Color(0xFF000000).obs;
  final secondaryColor = const Color(0xFFFFFFFF).obs;

  // Control de flujo
  bool _navigated = false;

  /// 🔹 Espera a que la vista esté montada (widgets listos)
  @override
  void onReady() {
    super.onReady();
    _loadBranding();
  }

  Future<void> _loadBranding() async {
    try {
      isLoading.value = true;
      error.value = null;

      // 1️⃣ Cargar desde caché (instantáneo)
      final cached = AppStorage.getOrganization();
      if (cached != null) _applyBranding(cached);

      // 2️⃣ Intentar obtener remoto
      try {
        final org = await _api.getOrganization();
        await AppStorage.setOrganization(org);
        _applyBranding(org);
      } catch (e) {
        debugPrint('⚠️ No se pudo actualizar branding remoto: $e');
      }

      await markImageShown();
    } catch (e) {
      error.value = 'Error cargando splash: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _applyBranding(OrganizationResponse org) {
    imageUrl.value = org.logo;
    primaryColor.value = _hexToColor(org.primaryColor);
    secondaryColor.value = _hexToColor(org.secondaryColor);
  }

  Future<void> markImageShown() async {
    Get.find<ThemeController>().refreshTheme();
    await Future.delayed(const Duration(seconds: 3));

    // 5️⃣ Navegar al login
    _goNext();
  }

  void _goNext() {
    if (_navigated) return;
    _navigated = true;

    final hasUser = AppStorage.getUser() != null;

    final goHome = hasUser;
    Get.offAllNamed(goHome ? Routes.home : Routes.login);
  }

  Color _hexToColor(String hex) {
    var clean = hex.replaceAll('#', '').toUpperCase();
    if (clean.length == 6) clean = 'FF$clean';
    final val = int.tryParse(clean, radix: 16) ?? 0xFF000000;
    return Color(val);
  }
}
