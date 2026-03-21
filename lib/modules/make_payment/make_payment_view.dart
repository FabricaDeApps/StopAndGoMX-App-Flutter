// lib/modules/payments/make_payment_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'make_payment_controller.dart';

class MakePaymentView extends GetView<MakePaymentController> {
  const MakePaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.maxAllowedAmount != null) ...[
                    Text(
                      'Saldo pendiente: \$${controller.maxAllowedAmount!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Monto
                  TextFormField(
                    controller: controller.amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      hintText: controller.maxAllowedAmount != null
                          ? controller.maxAllowedAmount!.toStringAsFixed(2)
                          : '210.00',
                      prefixIcon: Icon(Icons.attach_money),
                      helperText: 'No puede exceder el saldo pendiente',
                    ),
                    validator: controller.validateAmount,
                  ),
                  const SizedBox(height: 12),

                  // Método
                  DropdownButtonFormField<String>(
                    initialValue: controller.method.value,
                    decoration: const InputDecoration(
                      labelText: 'Método de pago',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                      DropdownMenuItem(
                        value: 'transfer',
                        child: Text('Transferencia'),
                      ),
                      DropdownMenuItem(value: 'card', child: Text('Tarjeta')),
                    ],
                    onChanged: (v) => controller.method.value = v ?? 'transfer',
                  ),
                  if (controller.method.value == 'transfer' &&
                      controller.hasBankDetailsHtml) ...[
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Datos bancarios',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copiar',
                                  onPressed:
                                      controller.copyBankDetailsToClipboard,
                                  icon: const Icon(Icons.content_copy_outlined),
                                ),
                              ],
                            ),
                            Html(
                              data: controller.bankDetailsHtml,
                              style: {
                                'body': Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  fontSize: FontSize(
                                    theme.textTheme.bodyMedium?.fontSize ?? 14,
                                  ),
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                                'p': Style(margin: Margins.only(bottom: 8)),
                                'ul': Style(margin: Margins.only(bottom: 8)),
                                'ol': Style(margin: Margins.only(bottom: 8)),
                                'a': Style(
                                  color: theme.colorScheme.primary,
                                  textDecoration: TextDecoration.underline,
                                ),
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Referencia (opcional)
                  TextFormField(
                    controller: controller.referenceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Referencia (opcional)',
                      hintText: 'BBVA1234',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fecha de pago
                  InkWell(
                    onTap: () => controller.pickDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de pago',
                        prefixIcon: Icon(Icons.event),
                      ),
                      child: Text(
                        controller.paidAt.value == null
                            ? 'Selecciona fecha'
                            : _fmtDate(controller.paidAt.value!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Imagen
                  Text(
                    'Comprobante (imagen)',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            controller.pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Cámara'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () =>
                            controller.pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (controller.pickedFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(controller.pickedFile!.path),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : controller.submit,
                      icon: controller.isSubmitting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Enviar recibo'),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
