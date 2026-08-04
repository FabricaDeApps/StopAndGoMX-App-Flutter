import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/dto/payment_dto.dart';
import 'package:stopandgo/core/models/dto/payment_provider_intent_dto.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/network/payment_intent_exception.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/role_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SpeiPaymentController extends GetxController with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 5);
  static const _maxPollingDuration = Duration(minutes: 2);

  final ApiRepository _api = Get.find<ApiRepository>();

  late final int paymentId;
  final payment = Rxn<PaymentDto>();
  final intent = Rxn<PaymentProviderIntentDto>();
  final isLoadingIntent = true.obs;
  final isRefreshingPayment = false.obs;
  final isOpeningInstructions = false.obs;
  final error = Rxn<PaymentIntentException>();
  final isPolling = false.obs;

  Timer? _pollTimer;
  DateTime? _pollStartedAt;
  bool _paidNotificationShown = false;

  bool get isPaid =>
      payment.value?.status == 'paid' ||
      (payment.value?.remainingAfterDiscountsAndReceipts ?? 1) <= 0;

  bool get canRegenerate => intent.value?.canRegenerate ?? false;

  String get statusLabel => switch (intent.value?.status) {
    'created' => 'Creando instrucciones',
    'action_required' => 'Transferencia pendiente',
    'pending' => 'Esperando confirmación',
    'approved' => 'Transferencia confirmada',
    'rejected' => 'Transferencia rechazada',
    'cancelled' => 'Intento cancelado',
    'expired' => 'Instrucciones vencidas',
    'failed' => 'No se pudo procesar',
    'superseded' => 'Instrucciones reemplazadas',
    _ => 'Estado pendiente',
  };

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    paymentId = Get.arguments?['paymentId'] as int? ?? 0;
    final incomingPayment = Get.arguments?['payment'];
    if (incomingPayment is PaymentDto) payment.value = incomingPayment;
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(createOrReuseIntent());
  }

  Future<void> createOrReuseIntent() async {
    if (paymentId <= 0) {
      error.value = const PaymentIntentException(
        statusCode: null,
        code: 'INVALID_PAYMENT',
        message: 'El pago seleccionado no es válido.',
      );
      isLoadingIntent.value = false;
      return;
    }

    isLoadingIntent.value = true;
    error.value = null;
    try {
      final result = await _api.createMercadoPagoIntent(
        paymentId: paymentId,
        paymentMethod: 'spei_transfer',
      );
      intent.value = result;
    } on PaymentIntentException catch (exception) {
      error.value = exception;
      if (exception.isPaymentCovered) await refreshPayment();
    } catch (_) {
      error.value = const PaymentIntentException(
        statusCode: null,
        code: 'INVALID_RESPONSE',
        message: 'No pudimos preparar las instrucciones de transferencia.',
      );
    } finally {
      isLoadingIntent.value = false;
    }
  }

  Future<void> openInstructions() async {
    if (isOpeningInstructions.value) return;
    final rawUrl = intent.value?.instructionsUrl;
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      Get.snackbar(
        'Transferencia SPEI',
        'Mercado Pago no devolvió una liga válida de instrucciones.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isOpeningInstructions.value = true;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        Get.snackbar(
          'Transferencia SPEI',
          'No fue posible abrir la liga de Mercado Pago.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      _startPolling();
      await refreshPayment();
    } catch (_) {
      Get.snackbar(
        'Transferencia SPEI',
        'No fue posible abrir la liga de Mercado Pago.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isOpeningInstructions.value = false;
    }
  }

  Future<void> copyReference() async {
    final reference = intent.value?.speiReference;
    if (reference == null || reference.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: reference));
    Get.snackbar(
      'Referencia copiada',
      'La referencia SPEI está lista para pegarse.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> refreshPayment({bool showFeedback = false}) async {
    if (isRefreshingPayment.value || paymentId <= 0) return;
    isRefreshingPayment.value = true;
    try {
      final user = AppStorage.getUser();
      if (user == null) return;
      final role = normalizeRole(
        user.activeRole.isNotEmpty ? user.activeRole : user.role,
      );

      List<PaymentDto> payments;
      if (hasManagerPrivileges(role)) {
        final categoryId = AppStorage.getSelectedCategoryId();
        if (categoryId == null || categoryId <= 0) return;
        payments = await _api.managerCategoryPayments(categoryId: categoryId);
      } else if (role == 'parent') {
        final playerId =
            payment.value?.playerId ?? AppStorage.getSelectedPlayerId();
        if (playerId == null || playerId <= 0) return;
        payments = await _api.playerMyPayments(playerId: playerId);
      } else {
        payments = await _api.myPayments();
      }

      final matches = payments.where((item) => item.id == paymentId);
      if (matches.isNotEmpty) payment.value = matches.first;

      if (isPaid) {
        _stopPolling();
        if (!_paidNotificationShown) {
          _paidNotificationShown = true;
          Get.snackbar(
            'Pago confirmado',
            'La transferencia fue aplicada correctamente.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else if (showFeedback) {
        Get.snackbar(
          'Estado actualizado',
          'La transferencia aún está pendiente de confirmación.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
      if (showFeedback) {
        Get.snackbar(
          'Actualizar estado',
          'No fue posible consultar el pago. Intenta nuevamente.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isRefreshingPayment.value = false;
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollStartedAt = DateTime.now();
    isPolling.value = true;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      final startedAt = _pollStartedAt;
      if (startedAt == null ||
          DateTime.now().difference(startedAt) >= _maxPollingDuration ||
          isPaid) {
        _stopPolling();
        return;
      }
      unawaited(refreshPayment());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollStartedAt = null;
    isPolling.value = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(refreshPayment());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopPolling();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.onClose();
  }
}
