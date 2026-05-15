import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/utils/app_navigator.dart';
import 'create_trainning_controller.dart';

class CreateTrainningView extends GetView<CreateTrainningController> {
  const CreateTrainningView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEditing ? 'Editar entrenamiento' : 'Nuevo entrenamiento',
        ),
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
                    onPressed: () => AppNavigator.maybePop(context),
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

                    // SEDE (Dropdown)
                    Text('Sede', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Obx(() {
                      if (controller.isLoadingVenues.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        );
                      }

                      if (controller.venuesError.value != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.venuesError.value!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // fallback a texto manual
                            TextFormField(
                              controller: controller.venueController,
                              decoration: InputDecoration(
                                hintText: 'Ej. Campo B',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final selectedId = controller.selectedVenueId.value;
                      Venue? selectedVenue;
                      if (selectedId != null) {
                        for (final v in controller.venues) {
                          if (v.id == selectedId) {
                            selectedVenue = v;
                            break;
                          }
                        }
                      }

                      return DropdownSearch<Venue>(
                        items: (f, cs) => controller.venues.toList(),
                        selectedItem: selectedVenue,
                        compareFn: (a, b) => a.id == b.id,
                        itemAsString: (v) => v.name,
                        onChanged: (v) =>
                            controller.selectedVenueId.value = v?.id,
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Buscar sede',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          itemBuilder: (context, item, isDisabled, isSelected) {
                            return ListTile(
                              dense: true,
                              title: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            hintText: 'Selecciona una sede',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        suffixProps: const DropdownSuffixProps(
                          clearButtonProps: ClearButtonProps(isVisible: true),
                          dropdownButtonProps: DropdownButtonProps(),
                        ),
                        clickProps: const ClickProps(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // STATUS
                    /*
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
                    */
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
                                : (controller.isEditing
                                      ? 'Guardar cambios'
                                      : 'Guardar entrenamiento'),
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
