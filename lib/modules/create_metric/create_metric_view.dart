import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'create_metric_controller.dart';

class CreateMetricView extends GetView<CreateMetricController> {
  const CreateMetricView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Métrica')),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _text(
                controller.nameCtrl,
                label: 'Nombre',
                hint: 'Salto vertical',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),

              _text(
                controller.keyCtrl,
                label: 'Key',
                hint: 'vertical_jump',
                readOnly: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),

              _text(controller.unitCtrl, label: 'Unidad', hint: 'cm'),
              Row(
                children: [
                  Expanded(
                    child: _dropdown(
                      label: 'Tipo',
                      value: controller.type,
                      items: const {'number': 'Número', 'time': 'Tiempo'},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdown(
                      label: 'Dirección',
                      value: controller.direction,
                      items: const {
                        'higher_is_better': 'Mayor es mejor',
                        'lower_is_better': 'Menor es mejor',
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _text(
                      controller.decimalsCtrl,
                      label: 'Decimales',
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _text(
                      controller.minCtrl,
                      label: 'Mínimo',
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _text(
                      controller.maxCtrl,
                      label: 'Máximo',
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Obx(
                () => SwitchListTile(
                  title: const Text('Activa'),
                  value: controller.isActive.value,
                  onChanged: (v) => controller.isActive.value = v,
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => ElevatedButton.icon(
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.createMetric,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _text(
    TextEditingController ctrl, {
    required String label,
    String? hint,
    bool readOnly = false,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
          suffixIcon: readOnly
              ? const Icon(Icons.lock_outline, size: 18)
              : null,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required RxString value,
    required Map<String, String> items,
  }) {
    return Obx(
      () => DropdownButtonFormField<String>(
        value: value.value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) => value.value = v!,
      ),
    );
  }
}
