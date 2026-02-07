// lib/modules/home/tabs/notices/notices_tab_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/dto/notice_model.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class NoticesTabController extends GetxController {
  final api = Get.find<ApiRepository>();

  // Contexto
  final role = ''.obs; // manager/coach/staff/parent/player
  final selectedCategoryId = RxnInt(); // por si luego filtras
  final selectedPlayerId = RxnInt(); // por si luego filtras

  // Estado
  final isLoading = false.obs;
  final listNotices = <Notice>[].obs;

  void setContext({required String userRole, int? categoryId, int? playerId}) {
    role.value = userRole;
    selectedCategoryId.value = categoryId;
    selectedPlayerId.value = playerId;
  }

  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      listNotices.clear();

      final r = role.value;

      if (r == 'staff') {
        final dtos = await api.getStaffNotices();
        listNotices.assignAll(dtos);
        return;
      }

      if (r == 'player' || r == 'parent') {
        final notices = await api.getMyNotices();
        listNotices.assignAll(notices);
        return;
      }

      if (r == 'manager' || r == 'coach') {
        final notices = await api.managerNotices();
        listNotices.assignAll(notices);
        return;
      }
    } catch (e, st) {
      debugPrint('[NoticesTabController] ❌ Error cargando avisos: $e\n$st');
      Get.snackbar(
        'Avisos',
        'No se pudieron cargar los avisos: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Opcional (fallback)
  // Future<void> _fallbackLoadLastNoticeFromDashboard(String r) async {
  //   try {
  //     if (r == 'player') {
  //       final dash = await api.getPlayerDashboard();
  //       final n = dash.lastNotice;
  //       _setSingleNotice(n);
  //     } else if (r == 'parent') {
  //       final dash = await api.getParentDashboard();
  //       final n = dash.lastNotice;
  //       _setSingleNotice(n);
  //     }
  //   } catch (_) {}
  // }
  //
  // void _setSingleNotice(dynamic n) {
  //   notices.clear();
  //   if (n == null) return;
  //
  //   DateTime date = DateTime.now();
  //   try {
  //     final published = n.publishedAt;
  //     final created = n.createdAt;
  //     if (published is DateTime) date = published;
  //     else if (published is String) date = DateTime.tryParse(published) ?? date;
  //     else if (created is DateTime) date = created;
  //     else if (created is String) date = DateTime.tryParse(created) ?? date;
  //   } catch (_) {}
  //
  //   notices.add(
  //     NoticeItem(
  //       id: (n.id as int),
  //       title: (n.title as String),
  //       message: n.message?.toString(),
  //       image: n.image?.toString(),
  //       attachment: n.attachment?.toString(),
  //       date: date,
  //     ),
  //   );
  // }
}
