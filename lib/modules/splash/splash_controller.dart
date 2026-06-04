// lib/modules/splash/splash_controller.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/network/auth_repository.dart';
import 'package:stopandgo/core/services/app_usage_session_service.dart';
import 'package:stopandgo/core/theme/theme_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/storage/app_storage.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';

class SplashController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final _auth = Get.find<AuthRepository>();

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

      // 2) Multi-org: restaura org cacheada para que el fetch remoto use ese id
      if (!FlavorConfig.I.isCustom) {
        final pendingOrgId = await AppStorage.consumePendingOrganizationId();
        if (pendingOrgId != null && pendingOrgId > 0) {
          FlavorConfig.I.updateOrganizationId(pendingOrgId);
        }

        final cachedOrg = AppStorage.getOrganization();
        final cachedOrgId = cachedOrg?.id;
        if ((pendingOrgId == null || pendingOrgId <= 0) &&
            cachedOrgId != null) {
          FlavorConfig.I.updateOrganizationId(cachedOrgId);
          _org = cachedOrg;
          _applyBranding(cachedOrg!);
        }
      }

      // 3) ORG remota según el orgId activo (flavor fijo o selección previa)
      _org = await _api.getOrganization();
      await AppStorage.setOrganization(_org!);
      _applyBranding(_org!);

      // 4) Espera RC
      await rcFuture;

      // 5) Check update (usa links de org)
      await _checkUpdate(_org);

      // 6) Aplica theme + espera splash mínimo
      Get.find<ThemeController>().refreshTheme();
      await Future.delayed(const Duration(seconds: 3));

      if (!_blockedByUpdate) await _goNext();
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
        'show_news': false,
        'announcement_enabled': false,
        'announcement_id': '',
        'announcement_type': 'image',
        'announcement_title': '',
        'announcement_body': '',
        'announcement_image_url': '',
        'announcement_video_url': '',
        'announcement_cta_label': '',
        'announcement_cta_url': '',
        'announcement_dismissible': true,
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
      await _showUpdateDialog(
        message: message,
        storeUrl: storeUrl,
        allowContinue: false,
      );
      return;
    }

    // ⚠️ No forzoso: muestra diálogo pero permite continuar
    _blockedByUpdate = false;

    if (!_navigated) {
      await _showUpdateDialog(
        message: message,
        storeUrl: storeUrl,
        allowContinue: true,
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

  Future<void> _showUpdateDialog({
    required String message,
    required String storeUrl,
    required bool allowContinue,
  }) async {
    await Get.dialog(
      PopScope(
        canPop: allowContinue,
        child: AlertDialog(
          title: Text(
            allowContinue
                ? 'Actualización disponible'
                : 'Actualización requerida',
          ),
          content: Text(message),
          actions: [
            if (allowContinue)
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Continuar'),
              ),
            FilledButton(
              onPressed: () async {
                await _openStoreUrl(storeUrl);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
      barrierDismissible: allowContinue,
    );
  }

  void _applyBranding(OrganizationResponse org) {
    imageUrl.value = org.logo;
    primaryColor.value = _hexToColor(org.primaryColor);
    secondaryColor.value = _hexToColor(org.secondaryColor);
  }

  Future<void> _goNext() async {
    if (_navigated) return;
    _navigated = true;

    final result = await _auth.restoreSession();
    final needsTeamSelector =
        !result.isAuthenticated && !FlavorConfig.I.isCustom;
    final next = result.isAuthenticated
        ? Routes.home
        : (needsTeamSelector ? Routes.teamSelector : Routes.login);
    debugPrint('session bootstrap: ${result.reason}');
    if (!result.isAuthenticated) {
      debugPrint('navigating unauthenticated कारण ${result.reason}');
    } else if (Get.isRegistered<AppUsageSessionService>()) {
      await Get.find<AppUsageSessionService>().handleAuthenticatedEntry(
        source: 'app_open',
      );
    }
    Get.offAllNamed(next);
  }

  Color _hexToColor(String hex) {
    var clean = hex.replaceAll('#', '').toUpperCase();
    if (clean.length == 6) clean = 'FF$clean';
    final val = int.tryParse(clean, radix: 16) ?? 0xFF000000;
    return Color(val);
  }
}
