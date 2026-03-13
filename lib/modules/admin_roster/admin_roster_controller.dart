import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/admin_player.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/routes/app_routes.dart';

class AdminRosterController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  final queryCtrl = TextEditingController();

  final isLoading = false.obs;
  final error = RxnString();
  final players = <AdminPlayer>[].obs;

  final activeFilter = 'all'.obs;
  final perPage = 25.obs;

  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final total = 0.obs;

  bool get hasPrevPage => currentPage.value > 1;
  bool get hasNextPage => currentPage.value < lastPage.value;

  @override
  void onInit() {
    super.onInit();
    loadPlayers();
  }

  Future<void> loadPlayers({int page = 1}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = null;

    try {
      final response = await _api.getAdminPlayers(
        q: queryCtrl.text.trim().isEmpty ? null : queryCtrl.text.trim(),
        active: activeFilter.value,
        perPage: perPage.value,
        page: page,
      );

      players.assignAll(response.data);
      currentPage.value = response.currentPage;
      lastPage.value = response.lastPage;
      total.value = response.total;
    } catch (e) {
      error.value = 'No se pudo cargar el roster general: $e';
      players.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> applyFilters() async {
    await loadPlayers(page: 1);
  }

  Future<void> clearFilters() async {
    queryCtrl.clear();
    activeFilter.value = 'all';
    perPage.value = 25;
    await loadPlayers(page: 1);
  }

  Future<void> goToEdit(AdminPlayer player) async {
    await Get.toNamed(
      Routes.adminPlayerEdit,
      arguments: {'player': player},
    );
    await loadPlayers(page: currentPage.value);
  }

  @override
  void onClose() {
    queryCtrl.dispose();
    super.onClose();
  }
}
