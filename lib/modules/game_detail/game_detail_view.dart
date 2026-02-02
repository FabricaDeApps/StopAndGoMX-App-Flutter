import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/games/game_comment.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/utils/helpers.dart';
import 'package:stopandgo/modules/game_detail/game_detail_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class GameDetailView extends GetView<GameDetailController> {
  const GameDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () => Get.toNamed(
              Routes.gameGallery,
              arguments: controller.game.value!.id,
            ),
          ),
          Obx(
            () => IconButton(
              onPressed: controller.toggleLike,
              icon: Icon(
                controller.isLiked.value
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: controller.isLiked.value
                    ? Colors.redAccent
                    : Colors.white,
              ),
              tooltip: 'Me gusta',
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final g = controller.game.value;
        if (g == null) {
          return const Center(child: Text('No se encontró el partido'));
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 380, child: _HeaderSlider(game: g)),

                  SizedBox(height: 10),
                  Center(child: _GalleryFab(gameId: g.id)),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: _GameInfoCard(game: g),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Comentarios',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Obx(() {
                    final list = controller.comments;
                    if (list.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text('Aún no hay comentarios. Sé el primero 👇'),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: list
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: _CommentTile(c: c),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 14,
                        offset: const Offset(0, -3),
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /*     IconButton(
                        onPressed: controller.onAddPhoto,
                        icon: const Icon(Icons.photo_camera_back_rounded),
                        tooltip: 'Agregar foto',
                      ), */
                      Expanded(
                        child: TextField(
                          controller: controller.commentCtrl,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => controller.sendComment(),
                          decoration: InputDecoration(
                            hintText: 'Escribe un comentario…',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: controller.sendComment,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _HeaderSlider extends StatelessWidget {
  final Game game;
  const _HeaderSlider({required this.game});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<GameDetailController>();

    return Obx(() {
      final imgs = c.images.isNotEmpty ? c.images.toList() : <String>[''];

      if (c.currentImage.value >= imgs.length) {
        c.currentImage.value = 0;
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            key: ValueKey(imgs.length),
            itemCount: imgs.length,
            onPageChanged: c.onImageChanged,
            itemBuilder: (_, i) {
              final url = imgs[i];
              if (url.isEmpty) {
                return Container(color: Colors.grey.shade300);
              }
              return Image.network(url, fit: BoxFit.cover);
            },
          ),

          // ✅ Gradient overlay sin bloquear gestos
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.70),
                  ],
                ),
              ),
            ),
          ),

          // ✅ Título + dots PEGADOS ABAJO (Positioned directo al Stack)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VS ${game.opponent}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(imgs.length, (i) {
                      final active = i == c.currentImage.value;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: active ? 18 : 6,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

// --- Reusa tus widgets existentes ---
class _GameInfoCard extends StatelessWidget {
  final Game game;
  const _GameInfoCard({required this.game});

  Future<void> _openInMaps({double? lat, double? lng, String? query}) async {
    Uri uri;

    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else if (query != null && query.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
      );
    } else {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final starts = game.startsAt;
    final venueObj = game.venueObj;

    String dateLabel() {
      if (starts == null) return '—';
      return '${starts.year}-${starts.month.toString().padLeft(2, '0')}-${starts.day.toString().padLeft(2, '0')} '
          '${starts.hour.toString().padLeft(2, '0')}:${starts.minute.toString().padLeft(2, '0')}';
    }

    String venueLabel() {
      final city = (venueObj?.city ?? '').trim();
      final state = (venueObj?.state ?? '').trim();

      final cityPart = city.isNotEmpty ? ' • $city' : '';
      final statePart = state.isNotEmpty ? ', $state' : '';

      return '${venueObj?.name}$cityPart$statePart';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Fecha/Hora', dateLabel()),
          const SizedBox(height: 8),
          _kv('Duración', '${game.durationMinutes ?? 0} min'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 90,
                child: Text(
                  'Sede',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openInMaps(
                    lat: game.lat,
                    lng: game.lng,
                    query: venueLabel(),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          venueLabel(),
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.location_pin,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _kv('Estatus', gameStatusLabel(game.status)),
          const SizedBox(height: 12),
          Text(
            'Notas',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(game.notes?.trim().isNotEmpty == true ? game.notes! : '—'),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(v)),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final GameComment c;
  const _CommentTile({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.authorName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(c.message),
        ],
      ),
    );
  }
}

class _GalleryFab extends StatelessWidget {
  final int gameId;
  const _GalleryFab({required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          await Get.toNamed(Routes.gameGallery, arguments: gameId);
          final c = Get.find<GameDetailController>();
          c.fetchGame();
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 6),
                color: Colors.black.withOpacity(0.18),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.photo_library_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Galería',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
