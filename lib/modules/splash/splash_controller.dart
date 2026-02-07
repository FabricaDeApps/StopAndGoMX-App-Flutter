// lib/modules/splash/splash_controller.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

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

  final appVersion = ''.obs;
  final buildNumber = ''.obs;

  // Update gate
  final _rc = FirebaseRemoteConfig.instance;
  bool _blockedByUpdate = false;

  // Org en memoria (sin cache)
  OrganizationResponse? _org;

  @override
  void onReady() {
    super.onReady();
    _boot();
  }

  Future<void> _boot() async {
    try {
      isLoading.value = true;
      error.value = null;

      await _loadVersion();

      // 1) Remote Config init/fetch (en paralelo)
      final rcFuture = _initRemoteConfig();

      // 2) ORG SIEMPRE REMOTA (sin cache)
      _org = await _api.getOrganization();
      await AppStorage.setOrganization(_org!);
      _applyBranding(_org!);

      // 3) Espera RC
      await rcFuture;

      // 4) Check update (usa links de org)
      await _checkUpdate(_org);

      // 5) Aplica theme + espera splash mínimo
      Get.find<ThemeController>().refreshTheme();
      await Future.delayed(const Duration(seconds: 3));

      if (!_blockedByUpdate) _goNext();
    } catch (e) {
      error.value = 'Error cargando la aplicación';
      debugPrint('❌ Splash error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = info.version;
    buildNumber.value = info.buildNumber;
  }

  Future<void> _initRemoteConfig() async {
    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );

      await _rc.setDefaults({
        'min_build_android': 0,
        'min_build_ios': 0,
        'force_update': false,
        'update_message':
            'Hay una nueva versión disponible. Actualiza para continuar.',
      });

      await _rc.fetchAndActivate();
    } catch (e) {
      debugPrint('⚠️ RemoteConfig init/fetch falló: $e');
    }
  }

  Future<void> _checkUpdate(OrganizationResponse? org) async {
    final currentBuild = int.tryParse(buildNumber.value) ?? 0;

    final minBuild = Platform.isAndroid
        ? _rc.getInt('min_build_android')
        : _rc.getInt('min_build_ios');

    if (minBuild <= 0) return;
    if (currentBuild >= minBuild) return;

    final force = _rc.getBool('force_update');

    final msgRaw = _rc.getString('update_message');
    final message = msgRaw.trim().isEmpty
        ? 'Hay una nueva versión disponible. Actualiza para continuar.'
        : msgRaw.trim();

    final storeUrl = _storeUrlFromOrg(org);

    if (force) {
      // ⛔ Bloquea y NO navega
      _blockedByUpdate = true;
      await _showForceUpdateDialog(message: message, storeUrl: storeUrl);
      return;
    }

    // ⚠️ No forzoso: solo aviso NO bloqueante y deja continuar
    _blockedByUpdate = false;

    if (!_navigated) {
      Get.snackbar(
        'Actualización disponible',
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(12),
        mainButton: TextButton(
          onPressed: () async => _openStoreUrl(storeUrl),
          child: const Text('Actualizar'),
        ),
      );
    }
  }

  String _storeUrlFromOrg(OrganizationResponse? org) {
    if (org == null) return '';
    if (Platform.isAndroid) {
      return (org.androidUrl ?? '').trim();
    } else {
      return (org.iosUrl ?? '').trim();
    }
  }

  Future<void> _openStoreUrl(String storeUrl) async {
    if (storeUrl.trim().isEmpty) {
      Get.snackbar('Info', 'No hay URL de tienda configurada');
      return;
    }
    final uri = Uri.tryParse(storeUrl.trim());
    if (uri == null) {
      Get.snackbar('Info', 'La URL de tienda es inválida');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      Get.snackbar('Info', 'No se pudo abrir la tienda');
    }
  }

  Future<void> _showForceUpdateDialog({
    required String message,
    required String storeUrl,
  }) async {
    await Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // no se puede cerrar
        child: AlertDialog(
          title: const Text('Actualización requerida'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () async {
                // En forzoso no permitimos cerrar,
                // solo intentamos abrir tienda y si falla mostramos mensaje.
                await _openStoreUrl(storeUrl);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _applyBranding(OrganizationResponse org) {
    imageUrl.value = org.logo;
    primaryColor.value = _hexToColor(org.primaryColor);
    secondaryColor.value = _hexToColor(org.secondaryColor);
  }

  void _goNext() {
    if (_navigated) return;
    _navigated = true;

    final hasUser = AppStorage.getUser() != null;
    Get.offAllNamed(hasUser ? Routes.home : Routes.login);
  }

  Color _hexToColor(String hex) {
    var clean = hex.replaceAll('#', '').toUpperCase();
    if (clean.length == 6) clean = 'FF$clean';
    final val = int.tryParse(clean, radix: 16) ?? 0xFF000000;
    return Color(val);
  }
}
