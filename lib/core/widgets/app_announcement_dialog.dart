import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:stopandgo/core/models/app_announcement.dart';

class AppAnnouncementDialog extends StatefulWidget {
  const AppAnnouncementDialog({super.key, required this.announcement});

  final AppAnnouncement announcement;

  @override
  State<AppAnnouncementDialog> createState() => _AppAnnouncementDialogState();
}

class _AppAnnouncementDialogState extends State<AppAnnouncementDialog> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLaunchingCta = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    if (widget.announcement.isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.announcement.videoUrl;
    if (url == null || url.trim().isEmpty) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.white,
          handleColor: Colors.white,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );

      if (!mounted) {
        chewie.dispose();
        await controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _chewieController = chewie;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _videoError = e.toString());
    }
  }

  Future<void> _openCta() async {
    final rawUrl = widget.announcement.ctaUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty || _isLaunchingCta) return;

    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      _showMessage('El enlace configurado es inválido.');
      return;
    }

    setState(() => _isLaunchingCta = true);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showMessage('No se pudo abrir el enlace.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo abrir el enlace.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunchingCta = false);
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final announcement = widget.announcement;
    final title = (announcement.title ?? '').trim();
    final body = (announcement.body ?? '').trim();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: AspectRatio(
                aspectRatio: announcement.isVideo
                    ? (_videoController?.value.aspectRatio ?? (16 / 9))
                    : (16 / 10),
                child: _buildMedia(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (title.isNotEmpty && body.isNotEmpty)
                    const SizedBox(height: 10),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (announcement.dismissible)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              announcement.hasCta ? 'Cerrar' : 'Continuar',
                            ),
                          ),
                        ),
                      if (announcement.dismissible && announcement.hasCta)
                        const SizedBox(width: 12),
                      if (announcement.hasCta)
                        Expanded(
                          child: FilledButton(
                            onPressed: _isLaunchingCta ? null : _openCta,
                            child: Text(
                              _isLaunchingCta
                                  ? 'Abriendo...'
                                  : announcement.ctaLabel!.trim(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    final announcement = widget.announcement;

    if (announcement.isImage) {
      return CachedNetworkImage(
        imageUrl: announcement.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, __, ___) =>
            _MediaFallback(message: 'No se pudo cargar la imagen.'),
      );
    }

    if (_videoError != null) {
      return const _MediaFallback(message: 'No se pudo cargar el video.');
    }

    final chewie = _chewieController;
    if (chewie == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(child: Chewie(controller: chewie)),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black12,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
