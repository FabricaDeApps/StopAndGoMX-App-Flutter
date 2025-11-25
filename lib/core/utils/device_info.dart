import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, String>> getDeviceInfo() async {
    String os = Platform.isAndroid ? 'android' : 'ios';
    String version = 'unknown';
    String model = 'unknown';

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      version = info.version.release; // ej. "14"
      model = info.model ?? 'Android';
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      version = info.systemVersion ?? 'iOS';
      model = info.utsname.machine ?? 'iPhone';
      // Ej: "iPhone14,2" → si quieres puedo mapearlo a nombre comercial
    }

    return {'os': os, 'os_version': version, 'device_model': model};
  }
}
