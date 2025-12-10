// lib/modules/player_documents/player_documents_controller.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/player_document.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class PlayerDocumentsController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  late final int playerId;
  late final String playerName;

  final documents = <PlayerDocument>[].obs;
  final isLoading = false.obs;
  final isUploading = false.obs;
  final isDeletingId = RxnInt();
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();

    playerId = Get.arguments['playerId'] as int;
    playerName = Get.arguments['playerName'] as String? ?? 'Jugador';

    loadDocuments();
  }

  Future<void> loadDocuments() async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _api.getPlayerDocuments(playerId);
      documents.assignAll(result);
    } catch (e) {
      error.value = 'Error al cargar documentos: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadDocument() async {
    try {
      isUploading.value = true;

      final result = await FilePicker.platform.pickFiles(
        withReadStream: false,
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) {
        return; // usuario canceló
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        Get.snackbar('Error', 'No se pudo leer el archivo seleccionado');
        return;
      }

      final file = File(filePath);

      final uploaded = await _api.uploadPlayerDocument(
        playerId: playerId,
        file: file,
      );

      documents.insert(0, uploaded);

      Get.snackbar(
        'Listo',
        'Documento subido correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo subir el documento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> deleteDocument(PlayerDocument doc) async {
    isDeletingId.value = doc.id;

    try {
      final ok = await _api.deletePlayerDocument(
        playerId: playerId,
        documentId: doc.id,
      );

      if (ok) {
        documents.removeWhere((d) => d.id == doc.id);
        Get.snackbar(
          'Eliminado',
          'Documento eliminado correctamente',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'No se pudo eliminar el documento',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar el documento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDeletingId.value = null;
    }
  }
}
