// lib/modules/player_documents/player_documents_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/models/player_documents_checklist.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'player_documents_controller.dart';
import 'package:stopandgo/core/models/player_document.dart';

class PlayerDocumentsView extends GetView<PlayerDocumentsController> {
  const PlayerDocumentsView({super.key});

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var i = 0;
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final f = DateFormat('dd/MM/yyyy HH:mm');
    return f.format(dt.toLocal());
  }

  Future<void> _confirmDelete(BuildContext context, PlayerDocument doc) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text(
          '¿Seguro que deseas eliminar el documento:\n"${doc.originalName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await controller.deleteDocument(doc);
    }
  }

  Future<void> _openDocument(PlayerDocument doc) async {
    final url = doc.downloadUrl;
    if (url.isEmpty) {
      Get.snackbar(
        'Error',
        'URL de descarga no disponible',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);

    if (!ok) {
      Get.snackbar(
        'Error',
        'No se pudo abrir el documento',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildProgressCard(
    BuildContext context,
    PlayerDocumentsChecklist checklist,
  ) {
    final summary = checklist.summary;
    final pct = (summary.percentage.clamp(0, 100) / 100).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso de documentos requeridos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: pct, minHeight: 10),
            const SizedBox(height: 8),
            Text(
              '${summary.completed}/${summary.totalRequired} completados'
              ' (${summary.percentage.toStringAsFixed(0)}%)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Faltantes: ${summary.missing}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredItem(
    BuildContext context,
    PlayerRequiredDocumentItem item,
  ) {
    final doc = item.document;
    final isUploaded = item.isUploaded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(isUploaded ? 'Cargado' : 'Pendiente'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: isUploaded
                      ? Colors.green.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: isUploaded ? Colors.green[800] : Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (item.description.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            if (doc != null)
              Text(
                '${doc.originalName} · ${_formatSize(doc.size)}'
                '${doc.uploadedAt != null ? ' · ${_formatDate(doc.uploadedAt)}' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              )
            else
              Text(
                'Aún no se ha subido archivo para este requisito.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            const SizedBox(height: 10),
            Obx(() {
              final isUploading =
                  controller.uploadingRequiredId.value == item.id;
              final isDeletingDoc =
                  doc != null && controller.isDeletingId.value == doc.id;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: isUploading
                        ? null
                        : () => controller.pickAndUploadRequiredDocument(item),
                    icon: isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(doc == null ? 'Subir' : 'Reemplazar'),
                  ),
                  if (doc != null)
                    OutlinedButton.icon(
                      onPressed: () => _openDocument(doc),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir'),
                    ),
                  if (doc != null)
                    OutlinedButton.icon(
                      onPressed: isDeletingDoc
                          ? null
                          : () => _confirmDelete(context, doc),
                      icon: isDeletingDoc
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalDocumentsSection(BuildContext context) {
    final docs = controller.additionalDocuments;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Documentos adicionales',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Obx(() {
                  final isUploading = controller.isUploadingAdditional.value;
                  return ElevatedButton.icon(
                    onPressed: isUploading
                        ? null
                        : controller.pickAndUploadAdditionalDocument,
                    icon: isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      isUploading ? 'Subiendo...' : 'Subir adicional',
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Text(
                'No hay documentos adicionales cargados.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return Obx(() {
                    final isDeleting = controller.isDeletingId.value == doc.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        doc.originalName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_formatSize(doc.size)}'
                        '${doc.uploadedAt != null ? ' · ${_formatDate(doc.uploadedAt)}' : ''}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Abrir',
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => _openDocument(doc),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: isDeleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.delete_outline),
                            onPressed: isDeleting
                                ? null
                                : () => _confirmDelete(context, doc),
                          ),
                        ],
                      ),
                    );
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documentos - ${controller.playerName}'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadAll(withLoader: false),
          ),
        ],
      ),
      body: Obx(() {
        final hasData =
            controller.checklist.value != null ||
            controller.documents.isNotEmpty;

        if (controller.isLoading.value && !hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null && !hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.error.value!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => controller.loadAll(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadAll(withLoader: false),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.error.value != null) ...[
                        Card(
                          color: Colors.red.withOpacity(0.08),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              controller.error.value!,
                              style: TextStyle(color: Colors.red[800]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (controller.checklist.value != null)
                        _buildProgressCard(
                          context,
                          controller.checklist.value!,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Checklist de requisitos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (controller.checklistItems.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No hay requisitos activos.'),
                          ),
                        )
                      else
                        ...controller.checklistItems.map(
                          (item) => _buildRequiredItem(context, item),
                        ),
                      const SizedBox(height: 12),
                      _buildAdditionalDocumentsSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
