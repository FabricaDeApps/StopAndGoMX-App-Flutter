// lib/modules/combine/create/combine_create_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/models/games.dart';
import 'combine_create_controller.dart';

class CombineCreateView extends GetView<CombineCreateController> {
  const CombineCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva evaluación')),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _SectionCard(
                title: 'Datos',
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Combine Semana 1',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty)
                          return 'El nombre es requerido';
                        if ((v ?? '').trim().length < 3)
                          return 'Nombre muy corto';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        hintText: 'Velocidad + agilidad',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Relaciones (IDs)',
                subtitle:
                    'Por ahora se capturan IDs. Luego lo cambiamos a dropdowns.',
                child: Column(
                  children: [
                    Obx(() {
                      if (controller.isLoadingCategories.value) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return DropdownButtonFormField<Category>(
                        isExpanded: true,
                        value: controller.selectedCategory.value,
                        items: controller.categories
                            .map(
                              (c) => DropdownMenuItem<Category>(
                                value: c,
                                child: Text(c.name ?? 'Categoría #${c.id}'),
                              ),
                            )
                            .toList(),
                        onChanged: (c) => controller.selectedCategory.value = c,
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: const Icon(Icons.groups_2),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: 'Recargar categorías',
                            onPressed: controller.loadCategories,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || (v.id ?? 0) <= 0)
                            return 'Selecciona una categoría';
                          return null;
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.isLoadingVenues.value) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return DropdownButtonFormField<Venue>(
                        isExpanded: true,
                        value: controller.selectedVenue.value,
                        items: controller.venues
                            .map(
                              (v) => DropdownMenuItem<Venue>(
                                value: v,
                                child: Text(v.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => controller.selectedVenue.value = v,
                        decoration: InputDecoration(
                          labelText: 'Sede (opcional)',
                          prefixIcon: const Icon(Icons.place_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: 'Recargar sedes',
                            onPressed: controller.loadVenues,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                        // opcional: no obligatoria
                        validator: (_) => null,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Fechas',
                child: Column(
                  children: [
                    Obx(() {
                      final s = controller.startsAt.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.play_circle_outline),
                        title: const Text('Inicio'),
                        subtitle: Text(_fmtDT(s) ?? 'Seleccionar'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => controller.pickStartsAt(context),
                      );
                    }),
                    const Divider(height: 1),
                    Obx(() {
                      final e = controller.endsAt.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.stop_circle_outlined),
                        title: const Text('Fin (opcional)'),
                        subtitle: Text(_fmtDT(e) ?? 'Seleccionar'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (e != null)
                              IconButton(
                                tooltip: 'Quitar',
                                onPressed: () => controller.endsAt.value = null,
                                icon: const Icon(Icons.clear),
                              ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => controller.pickEndsAt(context),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final err = controller.error.value;
                if (err == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(err, style: const TextStyle(color: Colors.red)),
                );
              }),
              const SizedBox(height: 6),
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.submit,
                    icon: controller.isSaving.value
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      controller.isSaving.value ? 'Guardando...' : 'Crear',
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static String? _fmtDT(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
