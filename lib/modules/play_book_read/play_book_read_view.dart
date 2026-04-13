import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/play_book_model.dart';
import 'package:stopandgo/modules/play_book_go/play_book_painter.dart';
import 'play_book_read_controller.dart';

class PlayBookReadView extends GetView<PlayBookReadController> {
  const PlayBookReadView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final alias = controller.playAlias.value.trim();
          return Text(
            alias.isEmpty ? 'PlayBook' : alias,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: controller.loadAll,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: controller.resetView,
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.play.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null && controller.play.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.error.value!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: controller.loadAll,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _metaCard(theme),
              const SizedBox(height: 12),
              if (controller.isGoMode) _goCanvas(theme) else _attachmentCard(theme),
              const SizedBox(height: 16),
              _feedbackSection(theme),
            ],
          ),
        );
      }),
    );
  }

  Widget _metaCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Obx(() {
          final play = controller.play.value;
          final sport = controller.playSport.value;
          final category = play?.category;
          final notes = controller.playNotes.value?.trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(theme, controller.playType.value.trim().isEmpty
                      ? '-'
                      : controller.playType.value.trim()),
                  _pill(theme, controller.sideLabel(controller.playSide.value)),
                  if (sport != null) _pill(theme, controller.sportLabel(sport)),
                  _pill(
                    theme,
                    play?.isAttachment == true ? 'Archivo' : 'GO',
                  ),
                ],
              ),
              if (category != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Categoría principal: ${category.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (controller.sharedCategories.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Compartida con',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.sharedCategories
                      .map((e) => Chip(label: Text(e.name)))
                      .toList(),
                ),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Notas', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(notes),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _goCanvas(ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pizarra', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 360,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.black12,
                  child: InteractiveViewer(
                    transformationController: controller.transformation,
                    minScale: 0.6,
                    maxScale: 3.5,
                    boundaryMargin: const EdgeInsets.all(200),
                    child: SizedBox(
                      width: controller.fieldSize.width,
                      height: controller.fieldSize.height,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) {
                          final world = controller.transformation.toScene(
                            d.localPosition,
                          );
                          final hit = controller.hitTestPlayer(world);
                          if (hit != null) controller.selectPlayer(hit);
                        },
                        child: Obx(() {
                          final selected = controller.selectedPlayerId.value;
                          return CustomPaint(
                            painter: PlayBookPainter(
                              fieldSize: controller.fieldSize,
                              players: controller.players.toList(),
                              selectedPlayerId: selected,
                              isDragging: false,
                              draggingPlayerId: null,
                              isDrawMode: false,
                              routesByPlayer: controller.routesByPlayer,
                              activeRoutePoints: const [],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Obx(() {
              final selId = controller.selectedPlayerId.value;
              return Text(
                selId == null ? 'Jugador: -' : 'Jugador seleccionado: $selId',
                style: theme.textTheme.bodySmall,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _attachmentCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Obx(() {
          final attachment = controller.play.value?.attachment;
          final attachmentName = attachment?.name?.trim();
          final isVideo = controller.isVideoAttachment(attachment);
          final isImage = controller.isImageAttachment(attachment);
          final label = attachmentName?.isNotEmpty == true
              ? attachmentName!
              : isVideo
                  ? 'Ver video adjunto'
                  : isImage
                      ? 'Ver imagen adjunta'
                      : 'Abrir archivo adjunto';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Archivo adjunto', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (attachment?.mimeType?.isNotEmpty == true)
                Text(
                  'Tipo: ${attachment!.mimeType}',
                  style: theme.textTheme.bodySmall,
                ),
              if (attachment?.sizeBytes != null)
                Text(
                  'Tamaño: ${attachment!.sizeBytes} bytes',
                  style: theme.textTheme.bodySmall,
                ),
              if (isVideo || isImage)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isVideo
                        ? 'Se reproduce dentro de la app.'
                        : 'Se muestra dentro de la app.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: controller.openPlayAttachment,
                icon: Icon(isVideo ? Icons.play_circle_fill : Icons.open_in_new),
                label: Text(label),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _feedbackSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Feedback',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Obx(() {
                  if (!controller.canSendFeedback) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    controller.userRole == 'player'
                        ? 'Jugador'
                        : 'Coach/Admin',
                    style: theme.textTheme.bodySmall,
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            _feedbackComposer(theme),
            const Divider(height: 28),
            Obx(() {
              if (controller.isLoadingFeedback.value &&
                  controller.feedbackItems.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.feedbackError.value != null &&
                  controller.feedbackItems.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.feedbackError.value!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: controller.loadFeedback,
                      child: const Text('Reintentar'),
                    ),
                  ],
                );
              }

              if (controller.feedbackItems.isEmpty) {
                return Text(
                  'Todavía no hay feedback en esta jugada.',
                  style: theme.textTheme.bodyMedium,
                );
              }

              return Column(
                children: controller.feedbackItems
                    .map((item) => _feedbackCard(theme, item))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _feedbackComposer(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller.feedbackCtrl,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Comentario',
            hintText: 'Ej. Revisen el timing del slot o sube un video.',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final fileLabel = controller.selectedFeedbackFileLabel.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fileLabel?.isNotEmpty == true
                          ? fileLabel!
                          : 'Sin archivo adjunto',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: controller.isPickingFeedbackFile.value
                        ? null
                        : controller.pickFeedbackAttachment,
                    icon: controller.isPickingFeedbackFile.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file),
                    label: const Text('Adjuntar'),
                  ),
                  if (fileLabel?.isNotEmpty == true) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Quitar archivo',
                      onPressed: controller.clearFeedbackAttachment,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.isSubmittingFeedback.value
                      ? null
                      : controller.submitFeedback,
                  icon: controller.isSubmittingFeedback.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    controller.isSubmittingFeedback.value
                        ? 'Enviando...'
                        : 'Enviar feedback',
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _feedbackCard(ThemeData theme, PlaybookFeedback item) {
    final photoUrl = item.author?.profilePhotoUrl?.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage:
                    photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
                child: photoUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        item.authorName.isNotEmpty
                            ? item.authorName.characters.first.toUpperCase()
                            : '?',
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.authorName,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (item.author?.role?.isNotEmpty == true)
                          item.author!.role!,
                        if (item.categoryName?.isNotEmpty == true)
                          item.categoryName!,
                        if (controller.feedbackTimestamp(item.createdAt).isNotEmpty)
                          controller.feedbackTimestamp(item.createdAt),
                      ].join(' • '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.message.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(item.message.trim()),
          ],
          if (item.attachment != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => controller.openFeedbackAttachment(item.attachment!),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                item.attachment!.name?.trim().isNotEmpty == true
                    ? item.attachment!.name!.trim()
                    : 'Abrir adjunto',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
