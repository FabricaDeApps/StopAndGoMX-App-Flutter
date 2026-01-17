import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/broadcast_live/broadcast_live_controller.dart';

class BroadcastLiveView extends GetView<BroadcastLiveController> {
  const BroadcastLiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transmitir (WebRTC)'),
        actions: [
          IconButton(
            tooltip: 'Cambiar cámara',
            icon: const Icon(Icons.cameraswitch),
            onPressed: controller.switchCamera,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error.value != null && !controller.isLive.value) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.error.value!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.start,
                    child: const Text('Reintentar transmitir'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(.25),
                    ),
                  ),
                  child: RTCVideoView(
                    controller.localRenderer,
                    mirror: false,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Obx(() {
                    final live = controller.isLive.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: live
                            ? Colors.red.withOpacity(.15)
                            : theme.colorScheme.primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        live ? 'EN VIVO' : 'LISTO',
                        style: TextStyle(
                          color: live ? Colors.red : theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  Text(
                    'LiveEvent #${controller.liveEventId}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),

              if (controller.error.value != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.error.value!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => ElevatedButton.icon(
                        icon: Icon(
                          controller.isLive.value
                              ? Icons.wifi
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          controller.isLive.value
                              ? 'Transmitiendo…'
                              : 'Iniciar transmisión',
                        ),
                        onPressed: controller.isLive.value
                            ? null
                            : controller.start,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => OutlinedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: const Text('Finalizar'),
                        onPressed: controller.isLive.value
                            ? () async {
                                await controller.stop();
                                Get.back();
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
