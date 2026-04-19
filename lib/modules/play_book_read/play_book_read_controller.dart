import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:chewie/chewie.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/models/play_book_model.dart';
import 'package:stopandgo/core/playbook/playbook_catalog.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class PlayBookReadController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final fieldSize = const Size(900, 520);

  // Pan/zoom (solo lectura)
  final transformation = TransformationController();

  // View state
  final isLoading = false.obs;
  final error = RxnString();
  final isLoadingFeedback = false.obs;
  final feedbackError = RxnString();
  final isPickingFeedbackFile = false.obs;
  final isSubmittingFeedback = false.obs;
  final isLikingPlay = false.obs;
  final deletingFeedbackIds = <int>{}.obs;

  // Args
  final playId = RxnString();

  // Data
  final play = Rxn<PlaybookPlay>();
  final playAlias = ''.obs;
  final playType = ''.obs;
  final playSide = ''.obs;
  final playNotes = RxnString();
  final playSport = Rxn<PlaySport>();
  final sharedCategories = <PlaybookCategoryRef>[].obs;
  final feedbackItems = <PlaybookFeedback>[].obs;

  final players = <PlayerToken>[].obs;
  final routesByPlayer = <String, List<PlayRoute>>{}.obs;

  // UI
  final selectedPlayerId = RxnString();
  final feedbackCtrl = TextEditingController();
  final selectedFeedbackFilePath = RxnString();
  final selectedFeedbackFileLabel = RxnString();

  String get userRole => AppStorage.getUser()?.role ?? 'player';
  bool get canSendFeedback => playId.value != null && playId.value!.isNotEmpty;
  bool get isAttachmentMode => play.value?.isAttachment == true;
  bool get isGoMode => play.value?.isGo == true;
  PlaybookLikes get likes => play.value?.likes ?? const PlaybookLikes();
  bool get hasFeedbackDraft {
    return feedbackCtrl.text.trim().isNotEmpty ||
        (selectedFeedbackFilePath.value?.isNotEmpty == true);
  }

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    final argPlayId = args?['playId']?.toString();

    if (argPlayId != null && argPlayId.isNotEmpty) {
      playId.value = argPlayId;
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (playId.value != null) {
      loadAll();
    } else {
      // Opcional: demo si abres sin args
      _seedDemo();
    }
  }

  @override
  void onClose() {
    transformation.dispose();
    feedbackCtrl.dispose();
    super.onClose();
  }

  Future<void> loadAll() async {
    final id = playId.value;
    if (id == null || id.isEmpty) return;

    await Future.wait([loadPlayFromBackend(id), loadFeedback()]);
  }

  Future<void> loadPlayFromBackend(String id) async {
    isLoading.value = true;
    error.value = null;

    try {
      final PlaybookPlay loadedPlay = await _api.getPlaybookPlay(playId: id);
      play.value = loadedPlay;

      // Meta
      playAlias.value = loadedPlay.alias;
      playType.value = loadedPlay.type;
      playSide.value = loadedPlay.side;
      playNotes.value = loadedPlay.notes;
      sharedCategories.assignAll(loadedPlay.sharedCategories);
      playSport.value = _inferSportFromContext(loadedPlay);

      // Data
      players.assignAll(loadedPlay.players);
      routesByPlayer.assignAll(loadedPlay.routesByPlayer);

      // Default selection
      selectedPlayerId.value = players.isNotEmpty ? players.first.id : null;

      // Reset zoom al cargar
      resetView();
    } catch (e) {
      error.value = 'Error al cargar jugada: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFeedback() async {
    final id = playId.value;
    if (id == null || id.isEmpty) return;

    isLoadingFeedback.value = true;
    feedbackError.value = null;

    try {
      final items = await _api.getPlaybookFeedback(playId: id);
      feedbackItems.assignAll(items);
    } catch (e) {
      feedbackError.value = 'Error al cargar feedback: $e';
    } finally {
      isLoadingFeedback.value = false;
    }
  }

  PlaySport _inferSportFromContext(PlaybookPlay play) {
    final normalizedType = play.type.trim().toLowerCase();
    if (normalizedType == 'playaction' || normalizedType == 'play action') {
      return PlaySport.americanFootball;
    }
    if (play.playersCount >= 9) {
      return PlaySport.americanFootball;
    }
    return PlaySport.flagFootball;
  }

  String sportLabel(PlaySport sport) => playSportLabel(sport);

  String sideLabel(String rawSide) {
    return rawSide.trim().toLowerCase() == 'defense'
        ? playSideLabel(PlaySide.defense)
        : playSideLabel(PlaySide.offense);
  }

  Future<void> openPlayAttachment() async {
    final attachment = play.value?.attachment;
    if (attachment == null || attachment.url.trim().isEmpty) {
      Get.snackbar(
        'Archivo',
        'Esta jugada no tiene un archivo válido para abrir.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await openAttachmentInApp(attachment, title: playAlias.value.trim());
  }

  Future<void> openFeedbackAttachment(PlaybookAttachment attachment) async {
    if (attachment.url.trim().isEmpty) {
      Get.snackbar(
        'Adjunto',
        'El adjunto no tiene una URL válida.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await openAttachmentInApp(
      attachment,
      title: attachment.name?.trim().isNotEmpty == true
          ? attachment.name!.trim()
          : 'Adjunto',
    );
  }

  bool isVideoAttachment(PlaybookAttachment? attachment) {
    if (attachment == null) return false;
    final mime = attachment.mimeType?.toLowerCase() ?? '';
    final kind = attachment.kind?.toLowerCase() ?? '';
    final url = attachment.url.toLowerCase();
    final name = attachment.name?.toLowerCase() ?? '';

    return kind == 'video' ||
        mime.startsWith('video/') ||
        url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.webm') ||
        name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.webm');
  }

  bool isImageAttachment(PlaybookAttachment? attachment) {
    if (attachment == null) return false;
    final mime = attachment.mimeType?.toLowerCase() ?? '';
    final kind = attachment.kind?.toLowerCase() ?? '';
    final url = attachment.url.toLowerCase();
    final name = attachment.name?.toLowerCase() ?? '';

    return kind == 'image' ||
        mime.startsWith('image/') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.webp') ||
        url.endsWith('.heic') ||
        url.endsWith('.heif') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.heic') ||
        name.endsWith('.heif');
  }

  Future<void> openAttachmentInApp(
    PlaybookAttachment attachment, {
    required String title,
  }) async {
    if (isVideoAttachment(attachment)) {
      await Get.to(
        () => _PlaybookVideoPage(
          title: title.isNotEmpty ? title : 'Video adjunto',
          url: attachment.url,
        ),
      );
      return;
    }

    if (isImageAttachment(attachment)) {
      await Get.to(
        () => _PlaybookImagePage(
          title: title.isNotEmpty ? title : 'Imagen adjunta',
          url: attachment.url,
        ),
      );
      return;
    }

    await _openUrl(attachment.url);
  }

  Future<void> _openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      Get.snackbar(
        'Archivo',
        'La URL del archivo no es válida.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'Archivo',
        'No se pudo abrir el archivo.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickFeedbackAttachment() async {
    try {
      isPickingFeedbackFile.value = true;

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'heif',
          'mp4',
          'mov',
          'webm',
        ],
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final path = picked.path;
      if (path == null || path.isEmpty) {
        Get.snackbar(
          'Feedback',
          'No se pudo leer el archivo seleccionado.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final file = File(path);
      if (!file.existsSync()) {
        Get.snackbar(
          'Feedback',
          'El archivo seleccionado no existe.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      selectedFeedbackFilePath.value = path;
      selectedFeedbackFileLabel.value = picked.name;
    } catch (e) {
      Get.snackbar(
        'Feedback',
        'No se pudo seleccionar el archivo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPickingFeedbackFile.value = false;
    }
  }

  void clearFeedbackAttachment() {
    selectedFeedbackFilePath.value = null;
    selectedFeedbackFileLabel.value = null;
  }

  Future<void> submitFeedback() async {
    final id = playId.value;
    if (id == null || id.isEmpty || isSubmittingFeedback.value) return;

    final message = feedbackCtrl.text.trim();
    final filePath = selectedFeedbackFilePath.value?.trim();

    if (message.isEmpty && (filePath == null || filePath.isEmpty)) {
      Get.snackbar(
        'Feedback',
        'Escribe un mensaje o adjunta un archivo.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSubmittingFeedback.value = true;
      final created = await _api.playbookCreateFeedback(
        playId: id,
        message: message,
        filePath: filePath,
      );
      feedbackItems.insert(0, created);
      feedbackCtrl.clear();
      clearFeedbackAttachment();
      feedbackItems.refresh();
      Get.snackbar(
        'Feedback',
        'Comentario enviado.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Feedback',
        'No se pudo enviar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmittingFeedback.value = false;
    }
  }

  bool isDeletingFeedback(int feedbackId) {
    return deletingFeedbackIds.contains(feedbackId);
  }

  Future<void> togglePlayLike() async {
    final currentPlay = play.value;
    final id = playId.value;
    if (currentPlay == null || id == null || id.isEmpty || isLikingPlay.value) {
      return;
    }

    final previous = currentPlay.likes;
    final optimisticLiked = !previous.isLiked;
    final optimisticCount = optimisticLiked
        ? previous.count + 1
        : (previous.count - 1).clamp(0, 1 << 30).toInt();

    isLikingPlay.value = true;
    play.value = currentPlay.copyWith(
      likes: previous.copyWith(
        isLiked: optimisticLiked,
        count: optimisticCount,
      ),
    );

    try {
      final updatedLikes = await _api.playbookToggleLike(playId: id);
      play.value = play.value?.copyWith(likes: updatedLikes);
    } catch (e) {
      play.value = play.value?.copyWith(likes: previous);
      Get.snackbar(
        'Jugada',
        'No se pudo actualizar el like: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLikingPlay.value = false;
    }
  }

  Future<void> deleteFeedback(PlaybookFeedback item) async {
    final id = playId.value;
    if (id == null ||
        id.isEmpty ||
        !item.canDelete ||
        deletingFeedbackIds.contains(item.id)) {
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Eliminar feedback'),
        content: const Text('¿Seguro que quieres eliminar este feedback?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    deletingFeedbackIds.add(item.id);
    deletingFeedbackIds.refresh();

    try {
      final deleted = await _api.playbookDeleteFeedback(
        playId: id,
        feedbackId: item.id,
      );
      if (!deleted) {
        throw Exception('El backend no confirmó el borrado.');
      }

      feedbackItems.removeWhere((e) => e.id == item.id);
      feedbackItems.refresh();
      Get.snackbar(
        'Feedback',
        'Comentario eliminado.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Feedback',
        'No se pudo eliminar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      deletingFeedbackIds.remove(item.id);
      deletingFeedbackIds.refresh();
    }
  }

  String feedbackTimestamp(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$min';
  }

  void resetView() {
    transformation.value = Matrix4.identity();
  }

  String? hitTestPlayer(Offset point, {double radius = 22}) {
    for (final p in players) {
      if ((p.pos - point).distance <= radius) return p.id;
    }
    return null;
  }

  void selectPlayer(String id) {
    selectedPlayerId.value = id;
  }

  // Demo opcional
  void _seedDemo() {
    players.assignAll(const [
      PlayerToken(id: 'qb', name: 'QB', pos: Offset(250, 260)),
      PlayerToken(id: 'wr1', name: 'WR1', pos: Offset(140, 180)),
    ]);
    routesByPlayer.assignAll({
      'wr1': [
        PlayRoute(
          id: 'r1',
          playerId: 'wr1',
          origin: Offset(140, 180), // si tu model usa originTokenPos
          points: [Offset.zero, Offset(120, 10), Offset(200, -40)],
        ),
      ],
    });
    playAlias.value = 'DEMO';
    playType.value = 'Pase';
    playSide.value = 'offense';
    playSport.value = PlaySport.flagFootball;
    selectedPlayerId.value = 'qb';
  }
}

class _PlaybookVideoPage extends StatefulWidget {
  final String title;
  final String url;

  const _PlaybookVideoPage({required this.title, required this.url});

  @override
  State<_PlaybookVideoPage> createState() => _PlaybookVideoPageState();
}

class _PlaybookVideoPageState extends State<_PlaybookVideoPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final vc = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await vc.initialize();

      final cc = ChewieController(
        videoPlayerController: vc,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
      );

      if (!mounted) {
        cc.dispose();
        await vc.dispose();
        return;
      }

      setState(() {
        _videoController = vc;
        _chewieController = cc;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cc = _chewieController;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Abrir externo',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : cc == null
                ? const CircularProgressIndicator()
                : AspectRatio(
                    aspectRatio: _videoController?.value.aspectRatio ?? (16 / 9),
                    child: Chewie(controller: cc),
                  ),
      ),
    );
  }
}

class _PlaybookImagePage extends StatelessWidget {
  final String title;
  final String url;

  const _PlaybookImagePage({required this.title, required this.url});

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Abrir externo',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.7,
        maxScale: 4,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined, size: 48),
          ),
        ),
      ),
    );
  }
}
