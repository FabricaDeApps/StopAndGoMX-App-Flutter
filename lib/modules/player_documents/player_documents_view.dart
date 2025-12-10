// lib/modules/player_documents/player_documents_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlayerDocumentsController>(
      init: PlayerDocumentsController(),
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: Text('Documentos - ${controller.playerName}')),
          floatingActionButton: Obx(() {
            final isUploading = controller.isUploading.value;
            return FloatingActionButton.extended(
              onPressed: isUploading
                  ? null
                  : () {
                      controller.pickAndUploadDocument();
                    },
              icon: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(isUploading ? 'Subiendo...' : 'Agregar'),
            );
          }),
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.error.value != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    controller.error.value!,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (controller.documents.isEmpty) {
              return const Center(
                child: Text('Aún no hay documentos cargados.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: controller.documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = controller.documents[index];
                final isDeleting = controller.isDeletingId.value == doc.id;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      doc.originalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${_formatSize(doc.size)}'
                          '${doc.uploadedAt != null ? ' · ${_formatDate(doc.uploadedAt)}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
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
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}
