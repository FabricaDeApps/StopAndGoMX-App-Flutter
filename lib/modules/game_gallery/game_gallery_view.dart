import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stopandgo/core/models/games/game_media_models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'game_gallery_controller.dart';

class GameGalleryView extends GetView<GameGalleryController> {
  const GameGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería del partido'),
        actions: [
          IconButton(
            onPressed: controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return Center(
            child: Text(
              controller.error.value!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final items = controller.items;

        return Stack(
          children: [
            Column(
              children: [
                _TopActions(controller: controller),
                const SizedBox(height: 8),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('Aún no hay fotos o videos'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _MediaTile(item: items[i]),
                        ),
                ),
              ],
            ),
            if (controller.isUploading.value)
              _UploadOverlay(controller: controller),
          ],
        );
      }),
    );
  }
}

class _TopActions extends StatelessWidget {
  final GameGalleryController controller;

  const _TopActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.isUploading.value
                  ? null
                  : controller.pickAndUploadImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Agregar fotos'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.isUploading.value
                  ? null
                  : controller.pickAndUploadVideo,
              icon: const Icon(Icons.video_call_outlined),
              label: const Text('Agregar video'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final GameMediaItem item;

  const _MediaTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.isVideo;
    final imageUrl = isVideo ? item.displayThumbnailUrl : item.displayImageUrl;

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          final hls = item.hlsUrl;
          if (hls == null || hls.isEmpty) {
            Get.snackbar('Video', 'Aún procesando o sin HLS disponible');
            return;
          }
          Get.to(() => _VideoPlayerPage(title: 'Video', hlsUrl: hls));
        } else {
          final url = item.displayImageUrl;
          if (url == null || url.isEmpty) return;
          Get.to(() => _ImagePreviewPage(url: url));
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black12),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              )
            else
              const Center(child: Icon(Icons.image_not_supported_outlined)),
            if (isVideo)
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UploadOverlay extends StatelessWidget {
  final GameGalleryController controller;
  const _UploadOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final idx = controller.uploadingIndex.value;
    final pct = (controller.uploadProgress.value * 100)
        .clamp(0, 100)
        .toDouble();

    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Subiendo...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: controller.uploadProgress.value),
                const SizedBox(height: 10),
                Text(
                  idx >= 0
                      ? 'Archivo ${idx + 1} • ${pct.toStringAsFixed(0)}%'
                      : '${pct.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No cierres la app mientras termina el upload.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Preview de imagen con "abrir" + "compartir"
class _ImagePreviewPage extends StatelessWidget {
  final String url;
  const _ImagePreviewPage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final uri = Uri.parse(url);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(url),
          ),
        ],
      ),
      body: InteractiveViewer(
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 48),
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerPage extends StatefulWidget {
  final String title;
  final String hlsUrl;

  const _VideoPlayerPage({required this.title, required this.hlsUrl});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final vc = VideoPlayerController.networkUrl(Uri.parse(widget.hlsUrl));
    await vc.initialize();

    final cc = ChewieController(
      videoPlayerController: vc,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
    );

    setState(() {
      _videoController = vc;
      _chewieController = cc;
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.hlsUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _share() => Share.share(widget.hlsUrl);

  @override
  Widget build(BuildContext context) {
    final cc = _chewieController;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openExternal,
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _share),
        ],
      ),
      body: Center(
        child: cc == null
            ? const CircularProgressIndicator()
            : AspectRatio(
                aspectRatio: _videoController?.value.aspectRatio ?? (16 / 9),
                child: Chewie(controller: cc),
              ),
      ),
    );
  }
}
