import 'package:flutter/material.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class BirthdayGreetingController extends GetxController {
  final fireworksController = FireworksController(
    colors: const [
      Color(0xFFFF6B35),
      Color(0xFFFFC145),
      Color(0xFF4ECDC4),
      Color(0xFF1A936F),
      Color(0xFFFF577F),
    ],
    minExplosionDuration: 0.8,
    maxExplosionDuration: 2.4,
    minParticleCount: 110,
    maxParticleCount: 230,
    fadeOutDuration: 0.35,
  );

  final title = 'Feliz cumpleaños'.obs;
  final body = ''.obs;
  final recipientName = ''.obs;
  final organizationName = ''.obs;
  final dateLabel = ''.obs;
  final avatarUrl = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? const {};

    title.value = _read(args, 'title', fallback: 'Feliz cumpleaños');
    recipientName.value = _read(
      args,
      'recipient_name',
      fallback:
          AppStorage.getSelectedPlayerName() ??
          AppStorage.getUser()?.name ??
          '',
    );
    organizationName.value = _read(
      args,
      'organization_name',
      fallback: AppStorage.getOrganization()?.name ?? '',
    );
    body.value = _read(
      args,
      'body',
      fallback: recipientName.value.isEmpty
          ? 'Hoy es un gran dia para celebrar.'
          : 'Hoy celebramos a ${recipientName.value}. Que tengas un dia increible.',
    );

    final rawDate = _read(args, 'date');
    dateLabel.value = _formatDate(rawDate);

    final sessionUser = AppStorage.getUser();
    final incomingAvatar = _read(args, 'avatar_url');
    avatarUrl.value = incomingAvatar.isNotEmpty
        ? incomingAvatar
        : ((sessionUser?.photoUrl?.isNotEmpty ?? false)
              ? sessionUser!.photoUrl
              : null);
  }

  @override
  void onReady() {
    super.onReady();
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      fireworksController.fireMultipleRockets(
        minRockets: 8,
        maxRockets: 14,
        launchWindow: const Duration(milliseconds: 1200),
      );
    });
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      fireworksController.fireMultipleRockets(
        minRockets: 5,
        maxRockets: 9,
        launchWindow: const Duration(milliseconds: 900),
      );
    });
  }

  String _read(Map<String, dynamic> args, String key, {String fallback = ''}) {
    final value = args[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;
    return DateFormat('dd MMMM yyyy', 'es_MX').format(parsed);
  }
}
