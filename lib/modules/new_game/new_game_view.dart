import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'new_game_controller.dart';

class NewGameView extends GetView<NewGameController> {
  const NewGameView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo juego')),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Rival
              TextFormField(
                controller: controller.opponentCtrl,
                decoration: const InputDecoration(labelText: 'Rival'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el rival' : null,
              ),
              const SizedBox(height: 12),

              // Buscador (opcional) + Dropdown venues
              Obx(() {
                if (controller.isLoadingVenues.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Cargando sedes...'),
                      ],
                    ),
                  );
                }

                final items = controller.filteredVenues;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: controller.venueSearchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Buscar sede',
                        hintText: 'Ej. Campo Central',
                        suffixIcon: controller.venueSearchCtrl.text.isEmpty
                            ? const Icon(Icons.search)
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    controller.venueSearchCtrl.clear(),
                              ),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField(
                      value: controller.selectedVenue.value,
                      decoration: const InputDecoration(
                        labelText: 'Sede / Campo',
                      ),
                      items: items
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text(v.name)),
                          )
                          .toList(),
                      onChanged: (v) => controller.selectedVenue.value = v,
                      validator: (v) => v == null ? 'Selecciona la sede' : null,
                    ),

                    if (controller.venues.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'No hay sedes registradas.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),

                    const SizedBox(height: 12),
                  ],
                );
              }),

              // Fecha y hora
              Obx(() {
                final dt = controller.scheduledAt.value;
                final text = (dt == null)
                    ? 'Selecciona fecha y hora'
                    : '${dt.day.toString().padLeft(2, '0')}/'
                          '${dt.month.toString().padLeft(2, '0')}/'
                          '${dt.year} '
                          '${dt.hour.toString().padLeft(2, '0')}:'
                          '${dt.minute.toString().padLeft(2, '0')}';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha y hora'),
                  subtitle: Text(text, style: theme.textTheme.bodyMedium),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () => controller.pickDateTime(context),
                );
              }),
              const SizedBox(height: 12),

              // Local
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Local'),
                  value: controller.isHome.value,
                  onChanged: (v) => controller.isHome.value = v,
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: controller.notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Primer juego de la temporada',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit
              Obx(
                () => SizedBox(
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
                        : const Icon(Icons.check),
                    label: Text(
                      controller.isSubmitting.value
                          ? 'Guardando...'
                          : 'Crear juego',
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
