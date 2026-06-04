import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'create_notice_controller.dart';

class CreateNoticeView extends GetView<CreateNoticeController> {
  const CreateNoticeView({super.key});

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return 'No definido';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo aviso')),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: controller.titleCtrl,
                maxLength: 180,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Ingresa el título';
                  if (value.length > 180) return 'Máximo 180 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller.messageCtrl,
                maxLength: 5000,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Mensaje'),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Ingresa el mensaje';
                  if (value.length > 5000) return 'Máximo 5000 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller.externalUrlCtrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Enlace externo (opcional)',
                  hintText: 'https://example.com',
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return null;
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                    return 'Ingresa una URL válida';
                  }
                  if (value.length > 2048) {
                    return 'Máximo 2048 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publicar aviso'),
                  value: controller.isPublished.value,
                  onChanged: (v) => controller.isPublished.value = v,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
                child: Text(
                  'Si no lo activas, se publicará en la fecha de publicación '
                  'si la eliges; si no eliges fecha, un administrador deberá '
                  'publicarlo manualmente.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Obx(
                () => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha de publicación (opcional)'),
                  subtitle: Text(_fmtDateTime(controller.publishedAt.value)),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      if (controller.publishedAt.value != null)
                        IconButton(
                          tooltip: 'Limpiar',
                          onPressed: () => controller.publishedAt.value = null,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      IconButton(
                        tooltip: 'Seleccionar fecha',
                        onPressed: () => controller.pickPublishedAt(context),
                        icon: const Icon(Icons.edit_calendar_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              Obx(
                () => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha de expiración (opcional)'),
                  subtitle: Text(_fmtDateTime(controller.expiresAt.value)),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      if (controller.expiresAt.value != null)
                        IconButton(
                          tooltip: 'Limpiar',
                          onPressed: () => controller.expiresAt.value = null,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      IconButton(
                        tooltip: 'Seleccionar fecha',
                        onPressed: () => controller.pickExpiresAt(context),
                        icon: const Icon(Icons.edit_calendar_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adjunto (opcional, máx 20MB)',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (controller.hasAttachment)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                controller.attachmentName.value ?? 'Archivo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: controller.clearAttachment,
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Quitar'),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Sin archivo seleccionado',
                          style: theme.textTheme.bodySmall,
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: controller.pickAttachment,
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          controller.hasAttachment
                              ? 'Cambiar adjunto'
                              : 'Seleccionar adjunto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                        : const Icon(Icons.campaign_outlined),
                    label: Text(
                      controller.isSubmitting.value
                          ? 'Creando aviso...'
                          : 'Crear aviso',
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
