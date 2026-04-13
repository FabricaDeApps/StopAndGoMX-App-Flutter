import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/playbook/playbook_catalog.dart';
import 'package:stopandgo/modules/play_book_create/play_book_create_controller.dart';

class PlayBookCreateView extends GetView<PlayBookCreateController> {
  const PlayBookCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear jugada')),
      body: Obx(() {
        return Stepper(
          currentStep: controller.stepIndex.value,
          onStepContinue: controller.next,
          onStepCancel: controller.back,
          controlsBuilder: (context, details) {
            final isLast = controller.stepIndex.value == 4;
            final canContinue = controller.canContinue;

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canContinue ? details.onStepContinue : null,
                      child: Text(isLast ? 'Continuar' : 'Siguiente'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(
                      controller.stepIndex.value == 0 ? 'Cerrar' : 'Atrás',
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Deporte'),
              subtitle: const Text('Flag o football americano'),
              isActive: controller.stepIndex.value >= 0,
              state: controller.isStep0Valid
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  _optionCard(
                    theme: theme,
                    selected: controller.sport.value == PlaySport.flagFootball,
                    title: 'Flag Football',
                    subtitle: 'Formato corto, normalmente 5 a 7 jugadores',
                    icon: Icons.sports_football,
                    onTap: () => controller.setSport(PlaySport.flagFootball),
                  ),
                  const SizedBox(height: 10),
                  _optionCard(
                    theme: theme,
                    selected:
                        controller.sport.value == PlaySport.americanFootball,
                    title: 'Football Americano',
                    subtitle: 'Formato tackle, normalmente 11 jugadores',
                    icon: Icons.shield,
                    onTap: () =>
                        controller.setSport(PlaySport.americanFootball),
                  ),
                ],
              ),
            ),

            Step(
              title: const Text('Lado'),
              subtitle: const Text('Ofensiva o Defensiva'),
              isActive: controller.stepIndex.value >= 1,
              state: controller.isStep1Valid
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  _optionCard(
                    theme: theme,
                    selected: controller.side.value == PlaySide.offense,
                    title: 'Ofensiva',
                    subtitle: 'Jugadas para anotar / avanzar',
                    icon: Icons.sports_football,
                    onTap: () => controller.setSide(PlaySide.offense),
                  ),
                  const SizedBox(height: 10),
                  _optionCard(
                    theme: theme,
                    selected: controller.side.value == PlaySide.defense,
                    title: 'Defensiva',
                    subtitle: 'Coberturas, blitz, ajustes',
                    icon: Icons.shield,
                    onTap: () => controller.setSide(PlaySide.defense),
                  ),
                ],
              ),
            ),

            Step(
              title: const Text('Tipo'),
              subtitle: const Text('Clasificación principal'),
              isActive: controller.stepIndex.value >= 2,
              state: controller.isStep2Valid
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.sport.value == null || controller.side.value == null)
                    const Text(
                      'Primero selecciona deporte y lado.',
                    ),
                  if (controller.sport.value != null &&
                      controller.side.value != null) ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: controller.typeOptions.map((t) {
                        final selected = controller.type.value == t;
                        return ChoiceChip(
                          label: Text(controller.typeLabel(t)),
                          selected: selected,
                          onSelected: (_) => controller.setType(t),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            Step(
              title: const Text('Jugadores'),
              subtitle: const Text('¿Cuántos participan?'),
              isActive: controller.stepIndex.value >= 3,
              state: controller.isStep3Valid
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Número de jugadores: ${controller.playersCount.value}',
                    style: theme.textTheme.titleMedium,
                  ),
                  Slider(
                    value: controller.playersCount.value.toDouble(),
                    min: 5,
                    max: 11,
                    divisions: 6,
                    label: controller.playersCount.value.toString(),
                    onChanged: (v) => controller.setPlayers(v.round()),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tip: flag suele 5–7, americano 11.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            Step(
              title: const Text('Modo'),
              subtitle: const Text('Playbook GO o adjuntar archivo'),
              isActive: controller.stepIndex.value >= 4,
              state: controller.isStep4Valid
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  _optionCard(
                    theme: theme,
                    selected: controller.mode.value == PlayMode.playbookGo,
                    title: 'Playbook GO',
                    subtitle: 'Editor: tokens + rutas (modo interactivo)',
                    icon: Icons.gesture,
                    trailing: _newPill(),
                    onTap: () => controller.setMode(PlayMode.playbookGo),
                  ),
                  const SizedBox(height: 10),
                  _optionCard(
                    theme: theme,
                    selected: controller.mode.value == PlayMode.attachment,
                    title: 'Adjuntar archivo',
                    subtitle: 'PDF / Imagen / Video / Documento',
                    icon: Icons.attach_file,
                    onTap: () => controller.setMode(PlayMode.attachment),
                  ),
                  const SizedBox(height: 12),
                  _shareCategoriesSection(theme),
                  const SizedBox(height: 12),
                  if (controller.mode.value == PlayMode.attachment)
                    _attachmentSection(theme),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _attachmentSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alias de la jugada', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Obx(() {
          return TextField(
            onChanged: controller.setAlias,
            decoration: InputDecoration(
              hintText: 'Ej. Sweep Right, Cover 2 Zone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: (controller.alias.value.trim().isEmpty)
                  ? 'Requerido'
                  : null,
            ),
          );
        }),
        const SizedBox(height: 14),

        Text('Archivo adjunto', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final name = controller.attachmentLabel.value;
                      return Text(
                        name?.isNotEmpty == true
                            ? name!
                            : 'Ningún archivo seleccionado',
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: controller.pickAttachment,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Elegir'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() {
                final hasFile =
                    (controller.attachmentPath.value ?? '').isNotEmpty;
                if (hasFile) return const SizedBox.shrink();
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Requerido',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shareCategoriesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compartir con otras categorías',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Opcional. La categoría principal sigue siendo la seleccionada en el home.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.isLoadingShareCategories.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final categories = controller.shareableCategories;
          if (categories.isEmpty) {
            return Text(
              'No hay más categorías disponibles para compartir.',
              style: theme.textTheme.bodySmall,
            );
          }

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final selected = controller.selectedSharedCategoryIds.contains(
                category.id,
              );

              return FilterChip(
                label: Text(category.name),
                selected: selected,
                onSelected: (_) => controller.toggleSharedCategory(category.id),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _newPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Nuevo',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _optionCard({
    required ThemeData theme,
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing,
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? theme.colorScheme.primary : theme.disabledColor,
            ),
          ],
        ),
      ),
    );
  }
}
