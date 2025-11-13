import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'create_trainning_controller.dart';

class CreateTrainningView extends GetView<CreateTrainningController> {
  const CreateTrainningView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo entrenamiento'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.error.value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FECHA/HORA
                    Text('Fecha y hora', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.startsAtController,
                      readOnly: true,
                      onTap: () => controller.pickStartsAt(context),
                      decoration: InputDecoration(
                        hintText: 'Selecciona fecha y hora',
                        prefixIcon: const Icon(Icons.event),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (_) {
                        if (controller.startsAtController.text.isEmpty) {
                          return 'Selecciona la fecha y hora';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // DURACIÓN
                    Text(
                      'Duración (minutos)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ej. 90',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SEDE
                    Text('Campo / sede', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.venueController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Campo B',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // DIRECCIÓN
                    Text('Dirección', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.addressController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Av. Deportiva 123',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CIUDAD
                    Text('Ciudad', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.cityController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Querétaro',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // STATUS
                    Text('Estado', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Obx(() {
                      return DropdownButtonFormField<String>(
                        value: controller.status.value,
                        items: const [
                          DropdownMenuItem(
                            value: 'scheduled',
                            child: Text('Programado'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completado'),
                          ),
                          DropdownMenuItem(
                            value: 'canceled',
                            child: Text('Cancelado'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) controller.status.value = value;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // NOTAS
                    Text('Notas', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ej. Trabajo físico y drills de pase',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BOTÓN GUARDAR
                    Obx(() {
                      final isSubmitting = controller.isSubmitting.value;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            isSubmitting
                                ? 'Guardando...'
                                : 'Guardar entrenamiento',
                          ),
                          onPressed: isSubmitting ? null : controller.submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
