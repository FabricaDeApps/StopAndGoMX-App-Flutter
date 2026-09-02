import 'package:get/get.dart';
import 'package:stopandgo/core/models/dto/payment_dto.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/role_utils.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentDetailController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  late final int paymentId;
  final payment = Rxn<PaymentDto>();
  final isLoading = true.obs;
  final error = RxnString();
  final isPayingWithCard = false.obs;

  bool get canPayWithCard =>
      AppStorage.getOrganization()?.payCardEnabled ?? false;
  bool get canPayWithSpei => canPayWithCard;

  bool get isPaid => payment.value?.status == 'paid';

  @override
  void onInit() {
    super.onInit();
    paymentId = Get.arguments?['paymentId'] as int? ?? 0;
    final fromArgs = Get.arguments?['payment'];
    if (fromArgs is PaymentDto) {
      payment.value = fromArgs;
    }
    loadPayment();
  }

  Future<void> loadPayment() async {
    if (paymentId <= 0) {
      error.value = 'Pago inválido.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    error.value = null;

    try {
      final user = AppStorage.getUser();
      if (user == null) {
        error.value = 'Sesión no encontrada. Inicia sesión de nuevo.';
        payment.value = null;
        return;
      }

      final role = user.activeRole.isNotEmpty ? user.activeRole : user.role;
      List<PaymentDto> list = const [];

      if (hasManagerPrivileges(role)) {
        final categoryId = AppStorage.getSelectedCategoryId();
        if (categoryId == null || categoryId <= 0) {
          error.value = 'No hay categoría seleccionada.';
          payment.value = null;
          return;
        }
        list = await _api.managerCategoryPayments(categoryId: categoryId);
      } else if (role == 'parent') {
        final playerId =
            payment.value?.playerId ?? AppStorage.getParentSelectedPlayerId();
        if (playerId == null || playerId <= 0) {
          error.value = 'No hay jugador seleccionado.';
          payment.value = null;
          return;
        }
        list = await _api.playerMyPayments(playerId: playerId);
      } else if (role == 'player') {
        final playerId = AppStorage.getAuthenticatedPlayerId();
        if (playerId == null || playerId <= 0) {
          error.value = 'No se encontró el perfil deportivo autenticado.';
          payment.value = null;
          return;
        }
        list = await _api.playerMyPayments(playerId: playerId);
      } else {
        list = await _api.myPayments();
      }

      final found = list.where((e) => e.id == paymentId).toList();
      if (found.isEmpty) {
        error.value = 'No se encontró el pago solicitado.';
        payment.value = null;
        return;
      }

      payment.value = found.first;
    } catch (e) {
      error.value = 'Error al cargar el pago: $e';
      payment.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToMakePayment() async {
    await Get.toNamed(
      Routes.makePayment,
      arguments: {
        'paymentId': paymentId,
        if (payment.value != null) 'payment': payment.value,
      },
    );
    await loadPayment();
  }

  Future<void> goToSpeiPayment() async {
    await Get.toNamed(
      Routes.speiPayment,
      arguments: {
        'paymentId': paymentId,
        if (payment.value != null) 'payment': payment.value,
      },
    );
    await loadPayment();
  }

  Future<void> payWithCard() async {
    if (isPayingWithCard.value) return;
    isPayingWithCard.value = true;
    try {
      final intent = await _api.createMercadoPagoIntent(paymentId: paymentId);
      final rawUrl = intent.initUrl;
      final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw Exception('Mercado Pago no devolvió una liga válida.');
      }
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
