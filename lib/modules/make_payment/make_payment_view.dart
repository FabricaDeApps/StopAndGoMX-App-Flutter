// lib/modules/payments/make_payment_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
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
                  // Monto
                  TextFormField(
                    controller: controller.amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      hintText: '210.00',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: controller.validateAmount,
                  ),
                  const SizedBox(height: 12),

                  // Método
                  DropdownButtonFormField<String>(
                    value: controller.method.value,
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
