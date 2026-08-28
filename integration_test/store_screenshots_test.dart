import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/main_academiapuebla.dart' as app;

const _username = String.fromEnvironment('STORE_REVIEW_USERNAME');
const _password = String.fromEnvironment('STORE_REVIEW_PASSWORD');
const _platform = String.fromEnvironment('STORE_SCREENSHOT_PLATFORM');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captura login, home y menú', (tester) async {
    expect(_username, isNotEmpty, reason: 'Falta STORE_REVIEW_USERNAME.');
    expect(_password, isNotEmpty, reason: 'Falta STORE_REVIEW_PASSWORD.');
    expect(
      _platform,
      anyOf('android', 'ios'),
      reason: 'STORE_SCREENSHOT_PLATFORM debe ser android o ios.',
    );

    await _clearLocalSession();
    await app.main();
    addTearDown(_logoutAndClearSession);

    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }

    await _pumpUntilFound(
      tester,
      find.byKey(const Key('store_login_screen')),
      timeout: const Duration(seconds: 45),
    );
    await _pumpUntilGone(
      tester,
      find.byType(CircularProgressIndicator),
      timeout: const Duration(seconds: 15),
    );
    await tester.pump(const Duration(seconds: 1));
    await _capture(binding, '01-login');

    await tester.enterText(
      find.byKey(const Key('store_login_email')),
      _username,
    );
    await tester.enterText(
      find.byKey(const Key('store_login_password')),
      _password,
    );
    final submit = find.byKey(const Key('store_login_submit'));
    final button = tester.widget<FilledButton>(submit);
    expect(button.onPressed, isNotNull);
    button.onPressed!();

    await _pumpUntilFound(
      tester,
      find.byKey(const Key('store_home_screen')),
      timeout: const Duration(seconds: 45),
    );
    await _pumpUntilGone(
      tester,
      find.text('Bienvenido'),
      timeout: const Duration(seconds: 10),
    );
    await tester.pump(const Duration(seconds: 2));
    await _dismissBirthdayPrompt(tester);
    await _capture(binding, '02-home');

    final scaffold = tester.state<ScaffoldState>(
      find.byKey(const Key('store_home_screen')),
    );
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    await _dismissBirthdayPrompt(tester);
    await _capture(binding, '03-home-menu');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<void> _clearLocalSession() async {
  await GetStorage.init('app_storage');
  await GetStorage('app_storage').erase();
  await GetStorage.init();
  await GetStorage().erase();
}

Future<void> _logoutAndClearSession() async {
  try {
    if (Get.isRegistered<ApiRepository>()) {
      await Get.find<ApiRepository>().logout(reason: 'store_screenshots');
    }
  } finally {
    await _clearLocalSession();
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isNotEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _dismissBirthdayPrompt(WidgetTester tester) async {
  final dismiss = find.text('Después');
  if (dismiss.evaluate().isEmpty) return;

  await tester.tap(dismiss);
  await tester.pumpAndSettle();
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  final bytes = await binding.takeScreenshot(name);
  expect(bytes, isNotEmpty);
}
