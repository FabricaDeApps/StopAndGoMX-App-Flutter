import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:stopandgo/core/models/combines/combine_metric.dart';
import 'package:stopandgo/core/network/api_client.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class CreateMetricController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // Controllers
  final keyCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
  final decimalsCtrl = TextEditingController(text: '1');
  final minCtrl = TextEditingController();
  final maxCtrl = TextEditingController();

  // Selectors
  final type = 'number'.obs;
  final direction = 'higher_is_better'.obs;
  final isActive = true.obs;

  final isLoading = false.obs;

  final _api = Get.find<ApiRepository>();

  @override
  void onInit() {
    super.onInit();

    nameCtrl.addListener(() {
      final text = nameCtrl.text;
      if (text.trim().isEmpty) {
        keyCtrl.text = '';
        return;
      }

      final generated = slugifyKey(text);

      // evita loops innecesarios
      if (keyCtrl.text != generated) {
        keyCtrl.text = generated;
      }
    });
  }

  @override
  void onClose() {
    keyCtrl.dispose();
    nameCtrl.dispose();
    unitCtrl.dispose();
    decimalsCtrl.dispose();
    minCtrl.dispose();
    maxCtrl.dispose();
    super.onClose();
  }

  Future<void> createMetric() async {
    // Ojo: formKey.currentState puede ser null si aún no se construye
    final ok = formKey.currentState?.validate() ?? false;
    if (!ok) return;

    try {
      isLoading.value = true;

      // Parseos seguros
      final decimals = int.tryParse(decimalsCtrl.text.trim()) ?? 2;

      final minText = minCtrl.text.trim();
      final maxText = maxCtrl.text.trim();
      final minVal = minText.isEmpty ? null : double.tryParse(minText);
      final maxVal = maxText.isEmpty ? null : double.tryParse(maxText);

      if (minText.isNotEmpty && minVal == null) {
        Get.snackbar('Error', 'Mínimo inválido');
        return;
      }
      if (maxText.isNotEmpty && maxVal == null) {
        Get.snackbar('Error', 'Máximo inválido');
        return;
      }
      if (minVal != null && maxVal != null && minVal > maxVal) {
        Get.snackbar('Error', 'El mínimo no puede ser mayor que el máximo');
        return;
      }

      final res = await _api.createCombineMetric(
        key: keyCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
        type: type.value,
        direction: direction.value,
        decimals: decimals,
        min: minVal,
        max: maxVal,
        isActive: isActive.value,
      );

      if (res == null) {
        Get.snackbar(
          'Error',
          'No se pudo crear la métrica',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      CombineMetric? metric;
      try {
        final raw = res['data'] ?? res['metric'] ?? res['result'] ?? res;
        if (raw is Map) {
          metric = CombineMetric.fromJson(Map<String, dynamic>.from(raw));
        }
      } catch (_) {
        metric = null;
      }

      Get.back(result: metric ?? true);

      Get.snackbar(
        'Éxito',
        'Métrica creada correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'No se pudo crear la métrica',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String slugifyKey(String input) {
    var s = input.trim().toLowerCase();

    // quitar acentos comunes
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    for (int i = 0; i < from.length; i++) {
      s = s.replaceAll(from[i], to[i]);
    }

    // solo letras, números y espacios
    s = s.replaceAll(RegExp(r'[^a-z0-9\s_]'), '');

    // espacios -> _
    s = s.replaceAll(RegExp(r'\s+'), '_');

    // colapsar __
    s = s.replaceAll(RegExp(r'_+'), '_');

    return s;
  }
}
