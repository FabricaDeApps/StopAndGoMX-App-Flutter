// lib/modules/payments/payments_controller.dart
import 'package:get/get.dart';
import 'package:stopandgo/core/models/dto/payment_dto.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

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

  late final int categoryId;

  @override
  void onInit() {
    super.onInit();
    categoryId = AppStorage.getSelectedCategoryId() ?? 0;
    loadPayments();
  }

  Future<void> loadPayments() async {
    isLoading.value = true;
    error.value = null;
    try {
      // Ajusta al método real que ya tengas
      final list = await _api.managerCategoryPayments(categoryId: categoryId);
      payments.assignAll(list);
    } catch (e) {
      error.value = 'Error al cargar pagos: $e';
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

    // orden opcional: por dueDate asc, luego id desc
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

  /// Si tu flujo de pagar con tarjeta vive en HomeController hoy,
  /// lo ideal es moverlo aquí (llamar API y navegar).
  /// Por ahora dejo el “wrapper” para que lo conectes a tu método real.
  Future<void> payWithCard(
    int paymentId,
    Future<void> Function() action,
  ) async {
    isPayingWithCard.value = true;
    try {
      await action();
      await loadPayments();
    } finally {
      isPayingWithCard.value = false;
    }
  }
}
