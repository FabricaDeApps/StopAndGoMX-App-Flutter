import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final outputRoot =
      Platform.environment['STORE_SCREENSHOT_OUTPUT'] ??
      'branding/academiapuebla/store/screenshots';
  final platform = Platform.environment['STORE_SCREENSHOT_PLATFORM'];
  if (platform != 'android' && platform != 'ios') {
    throw StateError('STORE_SCREENSHOT_PLATFORM debe ser android o ios.');
  }
  final deviceDirectory = platform == 'android'
      ? 'android/phone-raw'
      : 'ios/iphone-6.9-raw';

  await integrationDriver(
    driver: driver,
    onScreenshot: (name, bytes, [arguments]) async {
      final relativePath = '$deviceDirectory/$name.png';
      final segments = path.posix.split(relativePath);
      if (path.posix.isAbsolute(relativePath) || segments.contains('..')) {
        throw ArgumentError('Ruta de screenshot no permitida: $relativePath');
      }

      final destination = File(path.joinAll([outputRoot, ...segments]));
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(bytes, flush: true);
      return true;
    },
    writeResponseOnFailure: true,
  );
}
