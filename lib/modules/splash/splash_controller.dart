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

      // 1) Branding/org: cache primero (instantáneo)
      final cached = AppStorage.getOrganization();
      if (cached != null) _applyBranding(cached);

      // 2) Remote Config init/fetch (en paralelo)
      final rcFuture = _initRemoteConfig();

      // 3) Intentar org remoto
      OrganizationResponse? orgToUse = cached;
      try {
        final org = await _api.getOrganization();
        await AppStorage.setOrganization(org);
        orgToUse = org;
        _applyBranding(org);
      } catch (e) {
        debugPrint('⚠️ No se pudo actualizar org remoto: $e');
      }

      // Espera RC (si tarda, no quieres bloquear todo por siempre)
      await rcFuture;

      // 4) Check update (usa links de org)
      if (orgToUse != null) {
        await _checkUpdateAndMaybeBlock(orgToUse);
      } else {
        // Si no hay org, igual puedes checar update (pero sin URL no sirve abrir store)
        await _checkUpdateAndMaybeBlock(null);
      }

      // 5) Aplica theme + espera splash mínimo
      Get.find<ThemeController>().refreshTheme();
      await Future.delayed(const Duration(seconds: 3));

      if (!_blockedByUpdate) _goNext();
    } catch (e) {
      error.value = 'Error cargando splash: $e';
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

  Future<void> _checkUpdateAndMaybeBlock(OrganizationResponse? org) async {
    final currentBuild = int.tryParse(buildNumber.value) ?? 0;
    final minBuild = Platform.isAndroid
        ? _rc.getInt('min_build_android')
        : _rc.getInt('min_build_ios');

    if (minBuild <= 0) return;
    if (currentBuild >= minBuild) return;

    final force = _rc.getBool('force_update');
    final message = _rc.getString('update_message').trim().isEmpty
        ? 'Hay una nueva versión disponible. Actualiza para continuar.'
        : _rc.getString('update_message').trim();

    final storeUrl = _storeUrlFromOrg(org);

    _blockedByUpdate = force;

    await _showUpdateDialog(force: force, message: message, storeUrl: storeUrl);
  }

  String _storeUrlFromOrg(OrganizationResponse? org) {
    if (org == null) return '';
    if (Platform.isAndroid) {
      final v = (org.androidUrl ?? '').trim();
      return v;
    } else {
      final v = (org.iosUrl ?? '').trim();
      return v;
    }
  }

  Future<void> _showUpdateDialog({
    required bool force,
    required String message,
    required String storeUrl,
  }) async {
    await Get.dialog(
      WillPopScope(
        onWillPop: () async => !force,
        child: AlertDialog(
          title: Text(
            force ? 'Actualización requerida' : 'Actualización disponible',
          ),
          content: Text(message),
          actions: [
            if (!force)
              TextButton(
                onPressed: () {
                  _blockedByUpdate = false;
                  Get.back();
                },
                child: const Text('Después'),
              ),
            FilledButton(
              onPressed: () async {
                if (storeUrl.isEmpty) {
                  Get.snackbar('Info', 'No hay URL de tienda configurada');
                  return;
                }
                final uri = Uri.tryParse(storeUrl);
                if (uri == null) return;
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
      barrierDismissible: !force,
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
