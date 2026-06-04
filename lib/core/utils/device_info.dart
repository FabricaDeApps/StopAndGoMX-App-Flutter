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
      model = info.model;
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      version = info.systemVersion;
      model = info.utsname.machine;
      // Ej: "iPhone14,2" → si quieres puedo mapearlo a nombre comercial
    }

    return {'os': os, 'os_version': version, 'device_model': model};
  }

  static Future<Map<String, String>> getAppUsageDeviceInfo() async {
    String os = Platform.isAndroid ? 'android' : 'ios';
    String deviceId = 'unknown';
    String deviceName = 'unknown';

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      deviceId = info.id.trim().isEmpty ? 'android-${info.model}' : info.id;
      deviceName = info.model.trim().isEmpty ? 'Android' : info.model;
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      deviceId = (info.identifierForVendor ?? '').trim().isEmpty
          ? 'ios-${info.utsname.machine}'
          : info.identifierForVendor!.trim();
      deviceName = info.name.trim().isEmpty ? info.model : info.name.trim();
    }

    return {'os': os, 'device_id': deviceId, 'device_name': deviceName};
  }
}
