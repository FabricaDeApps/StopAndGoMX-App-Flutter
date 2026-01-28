import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stopandgo/core/models/checkin_model.dart';
import 'package:stopandgo/core/models/checkin_model_response.dart';
import 'package:stopandgo/core/models/checkin_response.dart';
import '../../../core/network/api_repository.dart';

class CheckinsController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = RxnString();

  final history = <CheckinModelResponse>[].obs;

  final dateFrom = ''.obs;
  final dateTo = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _setDefaultMonth();
    loadHistory();
  }

  void _setDefaultMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    dateFrom.value = _fmt(firstDay);
    dateTo.value = _fmt(lastDay);
  }

  String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      error.value = null;

      final items = await _api.getCheckinsHistory(
        dateFrom: dateFrom.value,
        dateTo: dateTo.value,
      );

      history.assignAll(items);
    } catch (e) {
      error.value = e.toString();
      history.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> doCheckin() async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;
      error.value = null;

      final position = await _getCurrentPosition();

      final response = await _api.createCheckin(
        checkin: CheckinModel(
          lat: position.latitude,
          lng: position.longitude,
          accuracyM: position.accuracy.isNaN ? null : position.accuracy.round(),
          source: 'app',
        ),
      );

      if (response == null) {
        _showErrorDialog(
          title: 'Error',
          message: 'No se pudo registrar el check-in.',
        );
        return;
      }

      if (!response.ok) {
        _showRejectedDialog(response);
        return;
      }

      _showSuccessDialog(response.message);
      await loadHistory();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSaving.value = false;
    }
  }

  void _showSuccessDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Listo'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showRejectedDialog(CheckinResponse res) {
    final distance = res.data?['distance_m'];
    final radius = res.data?['radius_m'];

    Get.dialog(
      AlertDialog(
        title: const Text('Check-in rechazado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(res.message),
            if (res.reason == 'out_of_radius' &&
                distance != null &&
                radius != null) ...[
              const SizedBox(height: 12),
              Text(
                'Distancia actual: ${distance} m\n'
                'Radio permitido: ${radius} m',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Activa tu GPS/Ubicación para poder hacer check-in.';
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permiso de ubicación denegado.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw 'Permiso de ubicación bloqueado. Actívalo en Configuración.';
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 12),
    );
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  void _showErrorDialog({required String title, required String message}) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
