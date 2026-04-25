import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/modules/home/home_controller.dart';
import 'package:stopandgo/modules/home/tabs/dashboard/models/dashboard_social_post.dart';

const _dashboardBackgroundGradient = LinearGradient(
  colors: [Color(0xFFF8F1E8), Color(0xFFF7F8FC), Color(0xFFEAF2F6)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class DashboardSocialComposerLauncher extends StatelessWidget {
  const DashboardSocialComposerLauncher({
    super.key,
    required this.onSearchMentions,
    required this.onSubmit,
  });

  final Future<List<DashboardMentionableUser>> Function(String query)
  onSearchMentions;
  final Future<void> Function(
    String caption,
    List<DashboardSocialMediaItem> media,
    List<DashboardMentionableUser> mentions,
  )
  onSubmit;

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    final user = AppStorage.getUser();
    final photoUrl = (homeCtrl?.userAvatar.value ?? user?.photoUrl ?? '')
        .trim();
    final userName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'Tu equipo';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _openComposer(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24,
                offset: Offset(0, 12),
                color: Color(0x12000000),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _UserAvatar(photoUrl: photoUrl, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF23343C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3EC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Comparte fotos, videos y menciona a tu gente...',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.open_in_full_rounded,
                                size: 18,
                                color: Color(0xFF35515E),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _ComposerActionPill(
                    icon: Icons.collections_outlined,
                    label: 'Fotos',
                    color: Color(0xFFE97C47),
                  ),
                  _ComposerActionPill(
                    icon: Icons.video_collection_outlined,
                    label: 'Videos',
                    color: Color(0xFF3C8D7A),
                  ),
                  _ComposerActionPill(
                    icon: Icons.alternate_email_rounded,
                    label: 'Menciones',
                    color: Color(0xFF5773D1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openComposer(BuildContext context) async {
    final result = await Get.to<_ComposerResult?>(
      () => DashboardCreatePostView(onSearchMentions: onSearchMentions),
      fullscreenDialog: true,
    );

    if (result == null) return;
    try {
      await onSubmit(result.caption, result.media, result.mentions);
    } catch (_) {
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu post ya apareció al inicio del feed.'),
        ),
      );
    }
  }
}

class DashboardCreatePostView extends StatefulWidget {
  const DashboardCreatePostView({super.key, required this.onSearchMentions});

  final Future<List<DashboardMentionableUser>> Function(String query)
  onSearchMentions;

  @override
  State<DashboardCreatePostView> createState() =>
      _DashboardCreatePostViewState();
}

class _DashboardCreatePostViewState extends State<DashboardCreatePostView> {
  final TextEditingController _captionCtrl = TextEditingController();
  final TextEditingController _mentionSearchCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<DashboardSocialMediaItem> _media = [];
  final List<DashboardMentionableUser> _mentions = [];
  final List<DashboardMentionableUser> _mentionResults = [];

  Timer? _mentionDebounce;

  bool _isSubmitting = false;
  bool _isSearchingMentions = false;

  bool get _canSubmit =>
      _captionCtrl.text.trim().isNotEmpty || _media.isNotEmpty;

  List<DashboardMentionableUser> get _filteredMentionSuggestions {
    return _mentionResults
        .where((item) => !_mentions.any((selected) => selected.id == item.id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _captionCtrl.addListener(() => setState(() {}));
    _mentionSearchCtrl.addListener(_onMentionQueryChanged);
    unawaited(_searchMentions(''));
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _mentionDebounce?.cancel();
    _mentionSearchCtrl
      ..removeListener(_onMentionQueryChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    final user = AppStorage.getUser();
    final photoUrl = (homeCtrl?.userAvatar.value ?? user?.photoUrl ?? '')
        .trim();
    final userName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'Tu equipo';

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Crear post'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Container(
          decoration: const BoxDecoration(
            gradient: _dashboardBackgroundGradient,
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: FilledButton.icon(
              onPressed: _canSubmit && !_isSubmitting ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF122B39),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? 'Publicando...' : 'Publicar ahora'),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: _dashboardBackgroundGradient,
          ),
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 24,
                        offset: Offset(0, 14),
                        color: Color(0x12000000),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _UserAvatar(photoUrl: photoUrl, radius: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF23343C),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Arma un post visual, claro y listo para publicar.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _captionCtrl,
                        minLines: 5,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText:
                              'Comparte algo importante para el equipo, celebra un logro o cuéntale a la comunidad qué está pasando...',
                          filled: true,
                          fillColor: const Color(0xFFF7F3EC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ComposerActionPill(
                            icon: Icons.collections_outlined,
                            label: 'Agregar fotos',
                            color: const Color(0xFFE97C47),
                            onTap: _pickPhotos,
                          ),
                          _ComposerActionPill(
                            icon: Icons.video_collection_outlined,
                            label: 'Agregar video',
                            color: const Color(0xFF3C8D7A),
                            onTap: _pickVideo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Vista previa',
                  subtitle: _media.isEmpty
                      ? 'Agrega varias fotos o combina con videos.'
                      : '${_media.length} elemento${_media.length == 1 ? '' : 's'} listo${_media.length == 1 ? '' : 's'} para publicar',
                  child: _media.isEmpty
                      ? const _EmptyStateTile(
                          icon: Icons.perm_media_outlined,
                          message: 'No has seleccionado fotos o videos.',
                        )
                      : SizedBox(
                          height: 172,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _media.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = _media[index];
                              return _SelectedMediaPreview(
                                item: item,
                                index: index,
                                onRemove: () {
                                  setState(() => _media.removeAt(index));
                                },
                              );
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Menciones',
                  subtitle: _mentions.isEmpty
                      ? 'Usa menciones para dar contexto y activar conversación.'
                      : 'Las menciones seleccionadas se agregarán al post.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_mentions.isEmpty)
                        const _EmptyStateTile(
                          icon: Icons.campaign_outlined,
                          message: 'Todavía no has mencionado a nadie.',
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _mentions
                              .map(
                                (mention) => InputChip(
                                  label: Text('@${mention.name}'),
                                  onDeleted: () {
                                    setState(() => _mentions.remove(mention));
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mentionSearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Buscar usuario para mencionar...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isSearchingMentions)
                        const Center(child: CircularProgressIndicator())
                      else if (_filteredMentionSuggestions.isEmpty)
                        const _EmptyStateTile(
                          icon: Icons.person_search_outlined,
                          message: 'No encontramos usuarios con ese nombre.',
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _filteredMentionSuggestions
                              .map(
                                (mention) => ActionChip(
                                  avatar: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  label: Text('@${mention.name}'),
                                  onPressed: () {
                                    setState(() {
                                      _mentions.add(mention);
                                      _mentionSearchCtrl.clear();
                                    });
                                    unawaited(_searchMentions(''));
                                  },
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    FocusScope.of(context).unfocus();
    final source = await _pickMediaSource('Selecciona fotos');
    if (source == null) return;

    if (source == ImageSource.gallery) {
      final items = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (items.isEmpty) return;

      setState(() {
        _media.addAll(
          items.map(
            (file) => DashboardSocialMediaItem(
              type: DashboardSocialMediaType.image,
              source: file.path,
              isLocal: true,
            ),
          ),
        );
      });
      return;
    }

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() {
      _media.add(
        DashboardSocialMediaItem(
          type: DashboardSocialMediaType.image,
          source: picked.path,
          isLocal: true,
        ),
      );
    });
  }

  Future<void> _pickVideo() async {
    FocusScope.of(context).unfocus();
    final source = await _pickMediaSource('Selecciona un video');

    if (source == null) return;

    final picked = await _picker.pickVideo(source: source);
    if (picked == null) return;

    setState(() {
      _media.add(
        DashboardSocialMediaItem(
          type: DashboardSocialMediaType.video,
          source: picked.path,
          isLocal: true,
          videoDurationLabel: 'Video',
        ),
      );
    });
  }

  Future<ImageSource?> _pickMediaSource(String title) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(title)),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galería'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Cámara'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onMentionQueryChanged() {
    _mentionDebounce?.cancel();
    _mentionDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_searchMentions(_mentionSearchCtrl.text)),
    );
  }

  Future<void> _searchMentions(String query) async {
    setState(() => _isSearchingMentions = true);
    try {
      final result = await widget.onSearchMentions(query.trim());
      if (!mounted) return;
      setState(() {
        _mentionResults
          ..clear()
          ..addAll(result);
      });
    } finally {
      if (mounted) {
        setState(() => _isSearchingMentions = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    Navigator.of(context).pop(
      _ComposerResult(
        caption: _captionCtrl.text.trim(),
        media: List<DashboardSocialMediaItem>.from(_media),
        mentions: List<DashboardMentionableUser>.from(_mentions),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.photoUrl, required this.radius});

  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD9E7EE),
      child: photoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person, color: Color(0xFF35515E)),
              ),
            )
          : const Icon(Icons.person, color: Color(0xFF35515E)),
    );
  }
}

class _ComposerActionPill extends StatelessWidget {
  const _ComposerActionPill({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 14),
            color: Color(0x12000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF23343C),
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyStateTile extends StatelessWidget {
  const _EmptyStateTile({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF35515E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}

class _SelectedMediaPreview extends StatelessWidget {
  const _SelectedMediaPreview({
    required this.item,
    required this.index,
    required this.onRemove,
  });

  final DashboardSocialMediaItem item;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final image = item.isLocal
        ? DecorationImage(
            image: FileImage(File(item.source)),
            fit: BoxFit.cover,
          )
        : DecorationImage(image: NetworkImage(item.source), fit: BoxFit.cover);

    return SizedBox(
      width: 146,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                image: image,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.38),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '#${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              children: [
                Icon(
                  item.isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.isVideo
                        ? (item.videoDurationLabel ?? 'Video')
                        : p.basename(item.source),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerResult {
  const _ComposerResult({
    required this.caption,
    required this.media,
    required this.mentions,
  });

  final String caption;
  final List<DashboardSocialMediaItem> media;
  final List<DashboardMentionableUser> mentions;
}
