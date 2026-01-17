import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'watch_live_controller.dart';

class WatchLiveView extends GetView<WatchLiveController> {
  const WatchLiveView({super.key});

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(controller.title), actions: [
          
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final err = controller.error.value;
          if (err != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    err,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: controller.load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // =======================
          // HLS UI
          // =======================
          if (controller.mode.value == WatchMode.hls) {
            final vc = controller.videoCtrl;

            if (vc == null || !vc.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            final aspect = (vc.value.aspectRatio == 0)
                ? (16 / 9)
                : vc.value.aspectRatio;

            return Column(
              children: [
                AspectRatio(
                  aspectRatio: aspect,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Positioned.fill(child: VideoPlayer(vc)),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: FloatingActionButton.small(
                            onPressed: controller.togglePlayPause,
                            child: Icon(
                              vc.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Reproduciendo HLS', style: theme.textTheme.bodyMedium),
              ],
            );
          }

          // =======================
          // WebRTC UI
          // =======================
          if (controller.mode.value == WatchMode.webrtc) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Obx(() {
                    if (!controller.webrtcReady.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return RTCVideoView(
                      controller.remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    );
                  }),
                ),

                // botón flotante
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    heroTag: 'stop-webrtc',
                    backgroundColor: Colors.black.withOpacity(0.6),
                    onPressed: controller.stopWebrtc,
                    child: const Icon(Icons.stop),
                  ),
                ),
              ],
            );
          }

          return Center(
            child: Text(
              'Sin modo de reproducción',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }),
      ),
    );
  }
}
