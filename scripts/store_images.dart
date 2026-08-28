import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _imageExtensions = {'.png', '.jpg', '.jpeg'};

void main(List<String> arguments) {
  if (arguments.length != 2 || arguments.first != '--config') {
    stderr.writeln('Uso: dart run scripts/store_images.dart --config RUTA');
    exitCode = 64;
    return;
  }

  final projectRoot = Directory.current.absolute;
  final configFile = File(_absolute(projectRoot, arguments[1]));
  final config =
      jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final store = config['store'] as Map<String, dynamic>;
  final assets = store['assets'] as Map<String, dynamic>;
  final screenshots = store['screenshots'] as Map<String, dynamic>;

  _buildPlayIcon(projectRoot, assets);
  _buildFeatureGraphic(projectRoot, assets);
  _normalizeScreenshots(
    projectRoot,
    sourceDirectory: screenshots['androidPhoneRawDirectory'] as String,
    destinationDirectory: screenshots['androidPhoneDirectory'] as String,
    android: true,
  );
  _normalizeScreenshots(
    projectRoot,
    sourceDirectory: screenshots['iosIphoneRawDirectory'] as String,
    destinationDirectory: screenshots['iosIphoneDirectory'] as String,
    android: false,
  );

  stdout.writeln('Assets de tienda generados para ${config['flavor']}.');
}

void _buildPlayIcon(Directory root, Map<String, dynamic> assets) {
  final source = _decode(root, assets['androidStoreIconSource'] as String);
  final output = _file(root, assets['androidStoreIcon'] as String);
  final icon = img.copyResize(
    source,
    width: 512,
    height: 512,
    interpolation: img.Interpolation.cubic,
  );
  _writePng(output, icon);
}

void _buildFeatureGraphic(Directory root, Map<String, dynamic> assets) {
  final background = _decode(
    root,
    assets['androidFeatureBackgroundSource'] as String,
  );
  final logo = _decode(root, assets['androidStoreIconSource'] as String);
  final canvas = _cover(background, 1024, 500).convert(numChannels: 3);
  final mark = img.copyResize(
    logo,
    height: 330,
    interpolation: img.Interpolation.cubic,
  );

  img.compositeImage(
    canvas,
    mark,
    dstX: 150,
    dstY: (canvas.height - mark.height) ~/ 2,
  );
  _writePng(
    _file(root, assets['androidFeatureGraphic'] as String),
    canvas.convert(numChannels: 3),
  );
}

void _normalizeScreenshots(
  Directory root, {
  required String sourceDirectory,
  required String destinationDirectory,
  required bool android,
}) {
  final source = Directory(_absolute(root, sourceDirectory));
  final destination = Directory(_absolute(root, destinationDirectory));
  destination.createSync(recursive: true);

  for (final entry in destination.listSync()) {
    if (entry is File && _isImage(entry.path)) entry.deleteSync();
  }

  final files =
      source
          .listSync()
          .whereType<File>()
          .where((file) => _isImage(file.path))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

  for (final file in files) {
    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) throw StateError('No se pudo leer ${file.path}');

    final normalized = android
        ? _androidScreenshot(decoded)
        : decoded.convert(numChannels: 3);
    final basename = file.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.(png|jpe?g)$', caseSensitive: false),
      '.png',
    );
    _writePng(File('${destination.path}/$basename'), normalized);
  }
}

img.Image _androidScreenshot(img.Image source) {
  const width = 1080;
  const height = 1920;
  final background = img.gaussianBlur(_cover(source, width, height), radius: 24)
    ..convert(numChannels: 3);
  final foreground = _contain(source, width, height);
  img.compositeImage(
    background,
    foreground,
    dstX: (width - foreground.width) ~/ 2,
    dstY: (height - foreground.height) ~/ 2,
  );
  return background.convert(numChannels: 3);
}

img.Image _cover(img.Image source, int width, int height) {
  final scale = math.max(width / source.width, height / source.height);
  final resized = img.copyResize(
    source,
    width: (source.width * scale).ceil(),
    height: (source.height * scale).ceil(),
    interpolation: img.Interpolation.cubic,
  );
  return img.copyCrop(
    resized,
    x: (resized.width - width) ~/ 2,
    y: (resized.height - height) ~/ 2,
    width: width,
    height: height,
  );
}

img.Image _contain(img.Image source, int width, int height) {
  final scale = math.min(width / source.width, height / source.height);
  return img.copyResize(
    source,
    width: (source.width * scale).round(),
    height: (source.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
}

img.Image _decode(Directory root, String path) {
  final file = _file(root, path);
  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) throw StateError('No se pudo leer ${file.path}');
  return decoded;
}

void _writePng(File output, img.Image image) {
  output.parent.createSync(recursive: true);
  output.writeAsBytesSync(img.encodePng(image), flush: true);
}

File _file(Directory root, String path) => File(_absolute(root, path));

String _absolute(Directory root, String path) =>
    File(path).isAbsolute ? path : '${root.path}/$path';

bool _isImage(String path) {
  final dot = path.lastIndexOf('.');
  return dot >= 0 &&
      _imageExtensions.contains(path.substring(dot).toLowerCase());
}
