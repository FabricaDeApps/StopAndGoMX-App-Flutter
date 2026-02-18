// lib/modules/payments/make_payment_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class MakePaymentController extends GetxController {
  final _api = Get.find<ApiRepository>();

  // Parámetro obligatorio: id del pago
  late final int paymentId;

  // Form
  final formKey = GlobalKey<FormState>();
  final amountCtrl = TextEditingController();
  final referenceCtrl = TextEditingController();
  final method = 'transfer'.obs; // default
  final paidAt = Rxn<DateTime>();

  // Imagen seleccionada
  final pickedPath = RxnString();
  File? get pickedFile =>
      pickedPath.value == null ? null : File(pickedPath.value!);

  // Loading
  final isSubmitting = false.obs;
  final organization = Rxn<OrganizationResponse>();

  @override
  void onInit() {
    super.onInit();
    paymentId = Get.arguments?['paymentId'] as int? ?? 0;
    organization.value = AppStorage.getOrganization();
  }

  @override
  void onClose() {
    amountCtrl.dispose();
    referenceCtrl.dispose();
    super.onClose();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, imageQuality: 85);
    if (x != null) {
      pickedPath.value = x.path;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = paidAt.value ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) paidAt.value = d;
  }

  String? validateAmount(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Ingresa el monto';
    final n = double.tryParse(s.replaceAll(',', '.'));
    if (n == null || n <= 0) return 'Monto inválido';
    return null;
  }

  String? validateDate() {
    if (paidAt.value == null) return 'Selecciona la fecha de pago';
    return null;
  }

  String? _validateImage() {
    if (pickedPath.value == null) return 'Selecciona una imagen';
    return null;
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get bankDetailsHtml {
    final raw = organization.value?.bankDetailsHtml ?? '';
    return _sanitizeBankDetailsHtml(raw);
  }

  bool get hasBankDetailsHtml => bankDetailsHtml.isNotEmpty;

  String get bankDetailsPlainText {
    if (!hasBankDetailsHtml) return '';
    var text = bankDetailsHtml;

    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");

    text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  Future<void> copyBankDetailsToClipboard() async {
    final text = bankDetailsPlainText;
    if (text.isEmpty) {
      Get.snackbar(
        'Datos bancarios',
        'No hay información para copiar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Datos bancarios',
      'Información copiada al portapapeles.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _sanitizeBankDetailsHtml(String input) {
    if (input.trim().isEmpty) return '';

    var sanitized = input;

    const blockedTags = <String>[
      'script',
      'style',
      'iframe',
      'object',
      'embed',
      'form',
      'input',
      'button',
      'textarea',
      'select',
      'option',
      'link',
      'meta',
    ];

    for (final tag in blockedTags) {
      // Remueve tags peligrosos completos.
      sanitized = sanitized.replaceAll(
        RegExp('<$tag[^>]*>.*?</$tag>', caseSensitive: false, dotAll: true),
        '',
      );

      // Remueve tags peligrosos auto-cerrados o sueltos.
      sanitized = sanitized.replaceAll(
        RegExp('<$tag[^>]*\\/?>', caseSensitive: false),
        '',
      );
    }

    // Remueve handlers inline tipo onclick=...
    sanitized = sanitized.replaceAll(
      RegExp(r'''\son\w+\s*=\s*(".*?"|'.*?'|[^\s>]+)''', caseSensitive: false),
      '',
    );

    // Bloquea href/src con javascript: o data:
    sanitized = sanitized.replaceAll(
      RegExp(
        r'''\s(href|src)\s*=\s*"\s*(javascript:|data:)[^"]*"''',
        caseSensitive: false,
      ),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(
        r"""\s(href|src)\s*=\s*'\s*(javascript:|data:)[^']*'""",
        caseSensitive: false,
      ),
      '',
    );

    return sanitized.trim();
  }

  Future<void> submit() async {
    // Validaciones de campos
    final validForm = formKey.currentState?.validate() ?? false;
    final imgErr = _validateImage();
    final dateErr = validateDate();
    if (!validForm || imgErr != null || dateErr != null) {
      if (imgErr != null) Get.snackbar('Imagen', imgErr);
      if (dateErr != null) Get.snackbar('Fecha', dateErr);
      return;
    }

    isSubmitting.value = true;
    try {
      await _api.createPlayerReceipt(
        paymentId: paymentId,
        amount: double.parse(amountCtrl.text.replaceAll(',', '.')),
        method: method.value,
        reference: referenceCtrl.text.trim().isEmpty
            ? null
            : referenceCtrl.text.trim(),
        paidAtYmd: _ymd(paidAt.value!),
        filePath: pickedPath.value!,
      );

      await Get.dialog(
        AlertDialog(
          title: const Text('¡Recibo enviado!'),
          content: const Text('Tu comprobante fue registrado correctamente.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(), // cierra dialog
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      // Regresa al tab de Pagos
      Get.back(); // cierra MakePaymentView
      // opcional: podrías refrescar lista desde onResume del tab o usando un callback
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo enviar el recibo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
