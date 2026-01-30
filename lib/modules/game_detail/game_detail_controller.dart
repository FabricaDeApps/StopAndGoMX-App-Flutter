import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/models/games/game_comment.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class GameDetailController extends GetxController {
  final api = Get.find<ApiRepository>();

  final isLoading = true.obs;
  final game = Rxn<Game>();

  // UI
  final currentImage = 0.obs;
  final isLiked = false.obs;

  // Comments
  final comments = <GameComment>[].obs;
  final commentCtrl = TextEditingController();
  final lastCommentId = 0.obs;

  // Slider images
  final images = <String>[].obs;

  late final int gameId;

  Timer? _pollTimer;
  bool _loadingComments = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map? ?? {};
    gameId = (args['id'] as int?) ?? 0;

    if (gameId > 0) {
      fetchGame();
    } else {
      isLoading.value = false;
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (gameId > 0) {
      _startPolling();
    }
  }

  Future<void> fetchGame() async {
    try {
      isLoading.value = true;

      final g = await api.getGameDetailById(gameId);
      if (g == null) {
        Get.snackbar('Error', 'No se pudo cargar el partido');
        return;
      }

      game.value = g;

      // Slider
      images.assignAll(g.images);
      currentImage.value = 0;

      // Like state (si tu modelo trae isLikedByMe)
      // Si tu Game no lo tiene aún, comenta estas dos líneas o ajusta
      try {
        isLiked.value = g.isLikedByMe ?? false;
      } catch (_) {
        // por si tu modelo aún no tiene isLikedByMe
      }

      // Carga inicial de comentarios
      await fetchCommentsInitial();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el partido');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------
  // Likes (juego)
  // ---------------------------
  Future<void> toggleLike() async {
    final prev = isLiked.value;
    isLiked.value = !prev; // optimista

    try {
      final res = await api.toggleGameLike(gameId);
      if (res == null) {
        isLiked.value = prev;
        return;
      }
      // Backend manda is_liked
      isLiked.value = (res['is_liked'] == true);
    } catch (_) {
      isLiked.value = prev;
    }
  }

  // ---------------------------
  // Slider
  // ---------------------------
  void onImageChanged(int index) => currentImage.value = index;

  void addImageUrl(String url) {
    if (url.trim().isEmpty) return;
    images.insert(0, url);
    currentImage.value = 0;
    images.refresh();
  }

  // ---------------------------
  // Comentarios - carga inicial + polling
  // ---------------------------
  Future<void> fetchCommentsInitial() async {
    if (_loadingComments) return;
    _loadingComments = true;
    try {
      final list = await api.getGameComments(gameId: gameId, limit: 30);

      comments.assignAll(list);

      // si vienen DESC (más nuevos primero), el last id es el primero
      if (comments.isNotEmpty) {
        lastCommentId.value = comments.first.id;
      } else {
        lastCommentId.value = 0;
      }
    } finally {
      _loadingComments = false;
    }
  }

  Future<void> fetchNewComments() async {
    if (_loadingComments) return;
    _loadingComments = true;
    try {
      final after = lastCommentId.value;
      if (after <= 0) {
        _loadingComments = false;
        return;
      }

      final newOnes = await api.getGameComments(
        gameId: gameId,
        afterId: after,
        limit: 50,
      );

      if (newOnes.isEmpty) return;

      // Backend (after_id) idealmente devuelve ASC.
      // Insertamos al inicio preservando orden y evitando duplicados.
      int maxId = after;

      for (final c in newOnes) {
        if (c.id > maxId) maxId = c.id;
        final exists = comments.any((x) => x.id == c.id);
        if (!exists) {
          comments.insert(0, c);
        }
      }

      if (maxId > lastCommentId.value) lastCommentId.value = maxId;
    } finally {
      _loadingComments = false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Solo si la pantalla sigue viva
      if (!isClosed) {
        fetchNewComments();
      }
    });
  }

  // ---------------------------
  // Enviar comentario (POST)
  // ---------------------------
  Future<void> sendComment() async {
    final text = commentCtrl.text.trim();
    if (text.isEmpty) return;

    // cierre teclado
    FocusManager.instance.primaryFocus?.unfocus();

    // opcional: limpiar de una vez
    commentCtrl.clear();

    try {
      final created = await api.createGameComment(
        gameId: gameId,
        message: text,
      );
      if (created == null) {
        Get.snackbar('Error', 'No se pudo enviar el comentario');
        return;
      }

      // Insertar arriba
      comments.insert(0, created);

      // actualizar lastCommentId
      if (created.id > lastCommentId.value) {
        lastCommentId.value = created.id;
      }
    } catch (_) {
      Get.snackbar('Error', 'No se pudo enviar el comentario');
    }
  }

  // ---------------------------
  // Agregar foto (subir)
  // ---------------------------
  /// Llama esto cuando ya tengas un File (picker/cámara).
  Future<void> uploadPhoto(File file) async {
    try {
      final url = await api.uploadGameImage(gameId: gameId, file: file);
      if (url == null || url.isEmpty) {
        Get.snackbar('Error', 'No se pudo subir la foto');
        return;
      }

      addImageUrl(url);
      Get.snackbar('Listo', 'Foto agregada');
    } catch (_) {
      Get.snackbar('Error', 'No se pudo subir la foto');
    }
  }

  final _picker = ImagePicker();

  Future<File?> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return file;

      // si es enorme, la bajamos a max 1600px
      final resized = img.copyResize(
        decoded,
        width: decoded.width > 1600 ? 1600 : decoded.width,
      );

      final jpg = img.encodeJpg(resized, quality: 82);

      final dir = await getTemporaryDirectory();
      final out = File(
        '${dir.path}/game_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await out.writeAsBytes(jpg, flush: true);
      return out;
    } catch (_) {
      return file; // fallback sin compresión
    }
  }

  Future<void> onAddPhoto() async {
    // Cierra teclado si estaba abierto
    FocusManager.instance.primaryFocus?.unfocus();

    final source = await Get.bottomSheet<ImageSource?>(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Agregar foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Tomar foto'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Elegir de galería'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      isScrollControlled: false,
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85, // compresión rápida del plugin
        maxWidth: 2000,
      );

      if (picked == null) return;

      var file = File(picked.path);

      // Compresión adicional (opcional pero buena)
      final compressed = await _compressImage(file);
      if (compressed != null) file = compressed;

      // ✅ subir al backend
      await uploadPhoto(file);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener la foto');
    }
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    commentCtrl.dispose();
    super.onClose();
  }
}
