import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'init_live_controller.dart';

class InitLiveView extends GetView<InitLiveController> {
  const InitLiveView({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Get.snackbar(
        'Error',
        'URL inválida',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      Get.snackbar(
        'Error',
        'No se pudo abrir el link',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _card({
    required BuildContext context,
    required String title,
    required String? value,
    required List<Widget> actions,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            value?.trim().isNotEmpty == true ? value! : '—',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(children: actions),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Live')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error.value != null) {
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
                    onPressed: controller.load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final publishUrl = controller.webrtcPublishUrl;
          final playUrl = controller.webrtcPlayUrl;
          final rtmpsUrl = controller.rtmpsUrl;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Antes de iniciar la transmisión, asegúrate de contar con una conexión a '
                  'internet estable y de tener autorización para transmitir este evento. '
                  'La calidad del video y audio dependerá de las condiciones de tu red y '
                  'del dispositivo utilizado.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.goLive,
                  child: const Text('Continuar a transmitir'),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
