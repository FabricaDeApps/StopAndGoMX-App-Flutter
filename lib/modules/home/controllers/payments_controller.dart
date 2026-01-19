// lib/modules/payments/payments_controller.dart
import 'package:get/get.dart';
import 'package:stopandgo/core/models/dto/payment_dto.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:url_launcher/url_launcher.dart';

enum PaymentStatusFilter { all, paid, pending, partial }

enum PaymentDueFilter { all, overdue, dueSoon }

extension PaymentStatusFilterX on PaymentStatusFilter {
  String get label => switch (this) {
    PaymentStatusFilter.all => 'Todos',
    PaymentStatusFilter.paid => 'Pagados',
    PaymentStatusFilter.pending => 'Pendientes',
    PaymentStatusFilter.partial => 'Parciales',
  };
}

extension PaymentDueFilterX on PaymentDueFilter {
  String get label => switch (this) {
    PaymentDueFilter.all => 'Todas',
    PaymentDueFilter.overdue => 'Vencidos',
    PaymentDueFilter.dueSoon => 'Por vencer',
  };
}

class PaymentsController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  final isLoading = true.obs;
  final payments = <PaymentDto>[].obs;
  final error = RxnString();

  // filtros
  final statusFilter = PaymentStatusFilter.all.obs;
  final dueFilter = PaymentDueFilter.all.obs;
  final query = ''.obs;
  final dueSoonDays = 7.obs;

  // UI states
  final isPayingWithCard = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPayments();
  }

  Future<void> loadPayments() async {
    isLoading.value = true;
    error.value = null;

    try {
      final user = AppStorage.getUser();
      if (user == null) {
        error.value = 'Sesión no encontrada. Inicia sesión de nuevo.';
        payments.clear();
        return;
      }

      List<PaymentDto> list = const [];

      if (user.role == 'manager') {
        payments.clear();
        final categoryId = AppStorage.getSelectedCategoryId();

        if (categoryId == null || categoryId <= 0) {
          error.value =
              'No hay categoría seleccionada. Regresa y selecciona una categoría.';
          payments.clear();
          return;
        }

        list = await _api.managerCategoryPayments(categoryId: categoryId);
      } else if (user.role == 'parent') {
        final playerId = AppStorage.getSelectedPlayerId();

        if (playerId == null || playerId <= 0) {
          error.value =
              'No hay jugador seleccionado. Regresa y selecciona un jugador.';
          payments.clear();
          return;
        }

        list = await _api.playerMyPayments(playerId: playerId);
      } else {
        // player / otros roles con pagos propios
        list = await _api.myPayments();
      }

      payments.assignAll(list);
    } catch (e) {
      error.value = 'Error al cargar pagos: $e';
      payments.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void setStatusFilter(PaymentStatusFilter v) => statusFilter.value = v;
  void setDueFilter(PaymentDueFilter v) => dueFilter.value = v;
  void setQuery(String v) => query.value = v;

  void clearFilters() {
    statusFilter.value = PaymentStatusFilter.all;
    dueFilter.value = PaymentDueFilter.all;
    query.value = '';
  }

  List<PaymentDto> get filteredPayments {
    final list = payments.toList();
    final q = query.value.trim().toLowerCase();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueSoonLimit = today.add(Duration(days: dueSoonDays.value));

    final out = list.where((p) {
      // status
      final okStatus = switch (statusFilter.value) {
        PaymentStatusFilter.all => true,
        PaymentStatusFilter.paid => p.status == 'paid',
        PaymentStatusFilter.pending => p.status == 'pending',
        PaymentStatusFilter.partial => p.status == 'partial',
      };
      if (!okStatus) return false;

      // due
      final okDue = switch (dueFilter.value) {
        PaymentDueFilter.all => true,
        PaymentDueFilter.overdue =>
          p.status != 'paid' && p.dueDate != null && p.dueDate!.isBefore(today),
        PaymentDueFilter.dueSoon =>
          p.status != 'paid' &&
              p.dueDate != null &&
              !p.dueDate!.isBefore(today) &&
              p.dueDate!.isBefore(dueSoonLimit),
      };
      if (!okDue) return false;

      // search
      if (q.isNotEmpty) {
        final haystack = '${p.playerName ?? ''} ${p.concept}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }

      return true;
    }).toList();

    out.sort((a, b) {
      final far = DateTime(2100);
      final ad = a.dueDate ?? far;
      final bd = b.dueDate ?? far;
      final c = ad.compareTo(bd);
      if (c != 0) return c;
      return b.id.compareTo(a.id);
    });

    return out;
  }

  Future<void> payWithCard(int paymentId) async {
    if (isPayingWithCard.value) return;

    isPayingWithCard.value = true;

    try {
      final intent = await _api.createMercadoPagoIntent(paymentId: paymentId);

      final uri = Uri.parse(intent.initUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        'Pago con tarjeta',
        'No se pudo iniciar el pago: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPayingWithCard.value = false;
    }
  }
}
