import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class CreateNoticeController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();

  final isPublished = true.obs;
  final publishedAt = Rxn<DateTime>();
  final expiresAt = Rxn<DateTime>();

  final attachmentPath = RxnString();
  final attachmentName = RxnString();

  final isSubmitting = false.obs;

  late final int categoryId;
  late final String role;

  bool get hasAttachment => (attachmentPath.value ?? '').trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>? ?? const {};

    categoryId =
        (args['categoryId'] as int?) ??
        AppStorage.getSelectedCategoryId() ??
        (throw ArgumentError('categoryId es requerido para crear aviso'));

    role =
        (args['role'] as String?)?.trim().toLowerCase() ??
        (AppStorage.getActiveRole() ?? '').trim().toLowerCase();
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    messageCtrl.dispose();
    super.onClose();
  }

  Future<void> pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      withReadStream: false,
      allowMultiple: false,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      Get.snackbar(
        'Adjunto',
        'No se pudo leer el archivo seleccionado.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final f = File(path);
    final bytes = await f.length();
    const maxBytes = 20 * 1024 * 1024;

    if (bytes > maxBytes) {
      Get.snackbar(
        'Adjunto',
        'El archivo excede el límite de 20MB.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    attachmentPath.value = path;
    attachmentName.value = file.name;
  }

  void clearAttachment() {
    attachmentPath.value = null;
    attachmentName.value = null;
  }

  Future<void> pickPublishedAt(BuildContext context) async {
    final now = DateTime.now();
    final initial = publishedAt.value ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    publishedAt.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> pickExpiresAt(BuildContext context) async {
    final now = DateTime.now();
    final base = expiresAt.value ?? publishedAt.value ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;

    expiresAt.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isSubmitting.value) return;

    isSubmitting.value = true;
    try {
      final title = titleCtrl.text.trim();
      final message = messageCtrl.text.trim();
      final attachment = attachmentPath.value;

      if (role == 'coach') {
        await _api.createCoachCategoryNotice(
          categoryId: categoryId,
          title: title,
          message: message,
          isPublished: isPublished.value,
          publishedAt: publishedAt.value,
          expiresAt: expiresAt.value,
          attachmentPath: attachment,
        );
      } else if (role == 'manager') {
        await _api.createManagerCategoryNotice(
          categoryId: categoryId,
          title: title,
          message: message,
          isPublished: isPublished.value,
          publishedAt: publishedAt.value,
          expiresAt: expiresAt.value,
          attachmentPath: attachment,
        );
      } else {
        throw Exception('Solo manager o coach pueden crear avisos.');
      }

      Get.back(result: true);
      Get.snackbar(
        'Avisos',
        'Aviso creado correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Avisos',
        _mapError(e),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final parsed = _extractErrorMessage(data);
      if (parsed != null) return parsed;

      if (error.response?.statusCode == 422) {
        return 'Datos inválidos para crear el aviso. Revisa los campos e intenta de nuevo.';
      }
    }

    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      final clean = text.replaceFirst('Exception: ', '');
      if (clean.contains('status code of 422') ||
          clean.contains('DioException [bad response]')) {
        return 'No se pudo crear el aviso: revisa título, mensaje y adjunto (máx 20MB).';
      }
      return clean;
    }
    if (text.contains('status code of 422') ||
        text.contains('DioException [bad response]')) {
      return 'No se pudo crear el aviso: revisa título, mensaje y adjunto (máx 20MB).';
    }
    return text;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first?.toString();
            if (first != null && first.trim().isNotEmpty) {
              return first.trim();
            }
          }
        }
      }
      return null;
    }

    if (data is Map) {
      return _extractErrorMessage(Map<String, dynamic>.from(data));
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }
}
