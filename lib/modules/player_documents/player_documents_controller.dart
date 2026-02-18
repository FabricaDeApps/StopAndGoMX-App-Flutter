// lib/modules/player_documents/player_documents_controller.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/player_document.dart';
import 'package:stopandgo/core/models/player_documents_checklist.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/widgets/snack_bar.dart';

class PlayerDocumentsController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  late final int playerId;
  late final String playerName;

  final documents = <PlayerDocument>[].obs;
  final checklist = Rxn<PlayerDocumentsChecklist>();
  final isLoading = false.obs;
  final isUploadingAdditional = false.obs;
  final uploadingRequiredId = RxnInt();
  final isDeletingId = RxnInt();
  final error = RxnString();

  List<PlayerRequiredDocumentItem> get checklistItems =>
      (checklist.value?.items ?? const <PlayerRequiredDocumentItem>[])
          .where((item) => item.isActive)
          .toList();

  List<PlayerDocument> get additionalDocuments {
    final docs = documents
        .where((doc) => doc.requiredDocumentId == null)
        .toList(growable: false);
    docs.sort((a, b) {
      final ad = a.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return docs;
  }

  @override
  void onInit() {
    super.onInit();

    playerId = Get.arguments['playerId'] as int;
    playerName = Get.arguments['playerName'] as String? ?? 'Jugador';

    loadAll();
  }

  Future<void> loadAll({bool withLoader = true}) async {
    if (withLoader) {
      isLoading.value = true;
    }
    error.value = null;

    try {
      final results = await Future.wait<dynamic>([
        _api.getPlayerDocumentsChecklist(playerId),
        _api.getPlayerDocuments(playerId),
      ]);

      checklist.value = results[0] as PlayerDocumentsChecklist;
      documents.assignAll(results[1] as List<PlayerDocument>);
    } catch (e) {
      error.value = _mapError(
        e,
        fallback: 'No se pudo cargar el checklist de documentos.',
      );
    } finally {
      if (withLoader) {
        isLoading.value = false;
      }
    }
  }

  Future<File?> _pickDocumentFile() async {
    final result = await FilePicker.platform.pickFiles(
      withReadStream: false,
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      UiSnackbar.error('Error', 'No se pudo leer el archivo seleccionado.');
      return null;
    }
    return File(filePath);
  }

  Future<void> pickAndUploadAdditionalDocument() async {
    try {
      isUploadingAdditional.value = true;
      final file = await _pickDocumentFile();
      if (file == null) {
        return;
      }

      await _api.uploadPlayerDocument(playerId: playerId, file: file);

      await loadAll(withLoader: false);
      UiSnackbar.success('Listo', 'Documento adicional subido correctamente.');
    } catch (e) {
      UiSnackbar.error(
        'Error',
        _mapError(e, fallback: 'No se pudo subir el documento adicional.'),
      );
    } finally {
      isUploadingAdditional.value = false;
    }
  }

  Future<void> pickAndUploadRequiredDocument(
    PlayerRequiredDocumentItem item,
  ) async {
    try {
      uploadingRequiredId.value = item.id;
      final file = await _pickDocumentFile();
      if (file == null) {
        return;
      }

      await _api.uploadPlayerDocument(
        playerId: playerId,
        file: file,
        requiredDocumentId: item.id,
      );

      await loadAll(withLoader: false);
      UiSnackbar.success(
        'Listo',
        item.document == null
            ? 'Documento requerido subido correctamente.'
            : 'Documento requerido reemplazado correctamente.',
      );
    } catch (e) {
      UiSnackbar.error(
        'Error',
        _mapError(e, fallback: 'No se pudo subir el documento requerido.'),
      );
    } finally {
      uploadingRequiredId.value = null;
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
        await loadAll(withLoader: false);
        UiSnackbar.success('Eliminado', 'Documento eliminado correctamente.');
      } else {
        UiSnackbar.error('Error', 'No se pudo eliminar el documento.');
      }
    } catch (e) {
      UiSnackbar.error(
        'Error',
        _mapError(e, fallback: 'No se pudo eliminar el documento.'),
      );
    } finally {
      isDeletingId.value = null;
    }
  }

  String _mapError(Object error, {required String fallback}) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final apiMessage = _extractApiMessage(error.response?.data);

      if (status == 403) {
        return apiMessage ??
            'No tienes permisos para gestionar documentos de este jugador.';
      }
      if (status == 404) {
        return apiMessage ??
            'No se encontró el jugador o el documento solicitado.';
      }
      if (status == 422) {
        return apiMessage ??
            'El archivo no es válido. Revisa formato y tamaño e intenta de nuevo.';
      }
      return apiMessage ?? fallback;
    }

    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return text.isEmpty ? fallback : text;
  }

  String? _extractApiMessage(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first?.toString();
            if (first != null && first.trim().isNotEmpty) {
              return first.trim();
            }
          }
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    }
    return null;
  }
}
