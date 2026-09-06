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
  if (platform != 'android' && platform != 'ios' && platform != 'ios-ipad') {
    throw StateError(
      'STORE_SCREENSHOT_PLATFORM debe ser android, ios o ios-ipad.',
    );
  }
  final deviceDirectory = platform == 'android'
      ? 'android/phone-raw'
      : platform == 'ios-ipad'
      ? 'ios/ipad-13-raw'
      : 'ios/iphone-6.9-raw';

  if (platform == 'ios-ipad') {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8879);
    server.listen((request) async {
      try {
        final name = request.uri.pathSegments.single;
        if (!['01-login', '02-home', '03-home-menu'].contains(name)) {
          throw ArgumentError('Escenario desconocido');
        }
        final destination = File(
          path.join(outputRoot, deviceDirectory, '$name.png'),
        );
        await destination.parent.create(recursive: true);
        final device = Platform.environment['STORE_SCREENSHOT_DEVICE'];
        if (device == null || device.isEmpty) {
          throw StateError('Falta device-id');
        }
        final result = await Process.run('xcrun', [
          'simctl',
          'io',
          device,
          'screenshot',
          destination.path,
        ]);
        if (result.exitCode != 0) throw StateError('${result.stderr}');
      } catch (error) {
        request.response.statusCode = 500;
        request.response.write('$error');
      }
      await request.response.close();
    });
  }

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
      if (platform != 'ios-ipad') {
        await destination.writeAsBytes(bytes, flush: true);
      }
      return true;
    },
    writeResponseOnFailure: true,
  );
}
