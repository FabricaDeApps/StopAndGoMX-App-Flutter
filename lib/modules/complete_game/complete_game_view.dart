import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'complete_game_controller.dart';

class CompleteGameView extends GetView<CompleteGameController> {
  const CompleteGameView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final past = controller.isPastGame; // getter no reactivo

    return Scaffold(
      appBar: AppBar(title: const Text('Completar juego')),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner (no requiere Obx)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: past
                      ? theme.colorScheme.primary.withOpacity(.06)
                      : theme.colorScheme.error.withOpacity(.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  past
                      ? 'Este juego ya pasó. Puedes capturar el marcador.'
                      : 'Aún no se puede completar: la fecha del juego no ha pasado.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Campos de marcador
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.homeScoreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Marcador Casa',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: controller.oppScoreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Marcador Rival',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔹 Evidence (reactivo)
              Obx(() {
                final file = controller.evidenceFile.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Evidencia (obligatoria)'),
                  subtitle: Text(
                    file == null ? 'Sin archivo seleccionado' : file.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.attach_file),
                    onSelected: (v) {
                      if (v == 'camera') {
                        controller.pickEvidence(ImageSource.camera);
                      } else {
                        controller.pickEvidence(ImageSource.gallery);
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'camera', child: Text('Tomar foto')),
                      PopupMenuItem(
                        value: 'gallery',
                        child: Text('Elegir de galería'),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // 🔹 Botón Guardar (reactivo por isSubmitting)
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: past && !controller.isSubmitting.value
                        ? controller.submit
                        : null,
                    icon: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      controller.isSubmitting.value
                          ? 'Guardando...'
                          : 'Guardar marcador',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
