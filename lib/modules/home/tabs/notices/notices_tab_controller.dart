// lib/modules/home/tabs/notices/notices_tab_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/modules/home/models/home_notice_item.dart';

class NoticesTabController extends GetxController {
  final api = Get.find<ApiRepository>();

  // Contexto
  final role = ''.obs; // manager/coach/staff/parent/player
  final selectedCategoryId = RxnInt(); // por si luego filtras
  final selectedPlayerId = RxnInt(); // por si luego filtras

  // Estado
  final isLoading = false.obs;
  final notices = <NoticeItem>[].obs;

  void setContext({required String userRole, int? categoryId, int? playerId}) {
    role.value = userRole;
    selectedCategoryId.value = categoryId;
    selectedPlayerId.value = playerId;
  }

  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      notices.clear();

      final r = role.value;

      if (r == 'staff') {
        // List<Notice> tipado
        final dtos = await api.getStaffNotices();

        final mapped = dtos.map((n) {
          return NoticeItem(
            id: n.id,
            title: n.title,
            message: n.message,
            image: n.image,
            attachment: n.attachment,
            date: n.publishedAt ?? DateTime.now(),
          );
        }).toList();

        notices.assignAll(mapped);
        return;
      }

      if (r == 'manager' || r == 'coach') {
        // List<Map<String,dynamic>>
        final list = await api.managerNotices();

        final mapped = list.map((m) {
          return NoticeItem(
            id: (m['id'] ?? 0) as int,
            title: (m['title'] ?? '') as String,
            message: m['message']?.toString(),
            image: m['image']?.toString(),
            attachment: m['attachment']?.toString(),
            date:
                DateTime.tryParse(
                  (m['published_at'] ?? m['created_at'] ?? '').toString(),
                ) ??
                DateTime.now(),
          );
        }).toList();

        notices.assignAll(mapped);
        return;
      }

      // Player/Parent:
      // Hoy tu app usa last_notice del dashboard, no un listado.
      // Aquí NO hacemos nada (tab queda vacío) para no duplicar llamadas.
      // Si quieres fallback, descomenta:
      //
      // await _fallbackLoadLastNoticeFromDashboard(r);
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
