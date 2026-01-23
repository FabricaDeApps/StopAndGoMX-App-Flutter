// lib/core/services/remote_config_update_service.dart
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateDecision {
  final bool needsUpdate; // build < minBuild
  final bool force; // force_update
  final int minBuild; // min_build_android/ios
  final int currentBuild; // build actual
  final String message;

  UpdateDecision({
    required this.needsUpdate,
    required this.force,
    required this.minBuild,
    required this.currentBuild,
    required this.message,
  });

  bool get mustUpdate => needsUpdate && force;
  bool get recommendUpdate => needsUpdate && !force;
}

class RemoteConfigUpdateService {
  final FirebaseRemoteConfig rc;

  RemoteConfigUpdateService(this.rc);

  Future<void> initAndFetch() async {
    // Ajusta a tu gusto
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );

    // Defaults para evitar nulls
    await rc.setDefaults({
      'min_build_android': 0,
      'min_build_ios': 0,
      'force_update': false,
      'update_message':
          'Hay una nueva versión disponible. Actualiza para continuar.',
    });

    await rc.fetchAndActivate();
  }

  Future<UpdateDecision> check() async {
    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;

    final minBuild = Platform.isAndroid
        ? rc.getInt('min_build_android')
        : rc.getInt('min_build_ios');

    final force = rc.getBool('force_update');

    final msg = rc.getString('update_message').trim().isEmpty
        ? 'Hay una nueva versión disponible. Actualiza para continuar.'
        : rc.getString('update_message').trim();

    final needsUpdate = (minBuild > 0) && (currentBuild < minBuild);

    return UpdateDecision(
      needsUpdate: needsUpdate,
      force: force,
      minBuild: minBuild,
      currentBuild: currentBuild,
      message: msg,
    );
  }
}
