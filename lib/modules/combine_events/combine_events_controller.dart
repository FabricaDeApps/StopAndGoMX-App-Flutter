// lib/modules/combine/events/combine_events_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/combines/combine_event.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/network/api_repository.dart';

class CombineEventsController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();

  final events = <CombineEvent>[].obs;

  // filtros UI (opcionales)
  final selectedCategoryId = RxnInt();
  final from = Rxn<DateTime>();
  final to = Rxn<DateTime>();

  final userRole = 'player'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSession();
    load();
  }

  void _loadSession() {
    final user = AppStorage.getUser();
    userRole.value = user?.role ?? 'player';
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      final categoryId = AppStorage.getSelectedCategoryId();

      final res = await _api.getCombineEvents(
        categoryId: categoryId,
        from: from.value,
        to: to.value,
      );

      if (res == null) {
        error.value = 'No se pudo cargar combines.';
        events.clear();
        return;
      }

      events.assignAll(res);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void clearFilters() {
    selectedCategoryId.value = null;
    from.value = null;
    to.value = null;
    load();
  }

  Future<void> pickFromDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = from.value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      from.value = picked;
      // si to < from, lo limpiamos
      if (to.value != null && to.value!.isBefore(picked)) to.value = null;
      load();
    }
  }

  Future<void> pickToDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = to.value ?? from.value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      to.value = picked;
      load();
    }
  }

  void openEvent(CombineEvent e) {
    final id = e.id;
    Get.toNamed(Routes.combineDetail, parameters: {'eventId': '$id'});
  }
}
