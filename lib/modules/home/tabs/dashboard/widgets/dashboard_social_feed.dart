import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/modules/home/tabs/dashboard/models/dashboard_social_post.dart';
import 'package:video_player/video_player.dart';

class DashboardSocialFeed extends StatelessWidget {
  const DashboardSocialFeed({
    super.key,
    required this.posts,
    required this.onLike,
    required this.onDeletePost,
    required this.onLikeComment,
    required this.onToggleComments,
    required this.onAddComment,
  });

  final List<DashboardSocialPost> posts;
  final Future<void> Function(int postId) onLike;
  final Future<void> Function(int postId) onDeletePost;
  final Future<void> Function(int postId, int commentId) onLikeComment;
  final Future<void> Function(int postId) onToggleComments;
  final Future<void> Function(int postId, String message) onAddComment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: posts
          .map(
            (post) => Padding(
              key: ValueKey('social-post-${post.id}'),
              padding: const EdgeInsets.only(bottom: 18),
              child: _SocialPostCard(
                post: post,
                onLike: () => onLike(post.id),
                onDelete: () => onDeletePost(post.id),
                onLikeComment: (commentIndex) =>
                    onLikeComment(post.id, commentIndex),
                onToggleComments: () => onToggleComments(post.id),
                onAddComment: (message) => onAddComment(post.id, message),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SocialPostCard extends StatefulWidget {
  const _SocialPostCard({
    required this.post,
    required this.onLike,
    required this.onDelete,
    required this.onLikeComment,
    required this.onToggleComments,
    required this.onAddComment,
  });

  final DashboardSocialPost post;
  final Future<void> Function() onLike;
  final Future<void> Function() onDelete;
  final Future<void> Function(int commentId) onLikeComment;
  final Future<void> Function() onToggleComments;
  final ValueChanged<String> onAddComment;

  @override
  State<_SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<_SocialPostCard> {
  late final TextEditingController _commentCtrl;
  late final FocusNode _commentFocusNode;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
    _commentFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final currentUserId = AppStorage.getUser()?.id ?? 0;
    final canDeletePost = currentUserId > 0 && post.authorId == currentUserId;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  _FeedAvatar(
                    photoUrl: post.authorAvatarUrl,
                    radius: 23,
                    heroTag: 'feed-avatar-${post.id}',
                    userName: post.authorName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${post.authorRole} · ${post.timeLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canDeletePost)
                    IconButton(
                      onPressed: _confirmDeletePost,
                      tooltip: 'Borrar post',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F0E8),
                        foregroundColor: const Color(0xFF6B4B3E),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.caption,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                  if (post.mentions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: post.mentions
                          .map(
                            (mention) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9F0FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '@${mention.name}',
                                style: const TextStyle(
                                  color: Color(0xFF355EC9),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 14),
              _MediaPreview(post: post),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Text(
                    '${post.likesCount} likes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${post.commentsCount} comentarios',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleCommentsVisibility,
                    tooltip: post.commentsExpanded
                        ? 'Ocultar comentarios'
                        : 'Ver comentarios',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF7F3EC),
                      foregroundColor: const Color(0xFF35515E),
                    ),
                    icon: Icon(
                      post.commentsExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onLike,
                      icon: Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? const Color(0xFFE74C3C) : null,
                      ),
                      label: Text(post.isLiked ? 'Te gusta' : 'Me gusta'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _handleCommentTap,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Comentar'),
                    ),
                  ),
                ],
              ),
            ),
            if (post.commentsExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  children: [
                    for (final entry
                        in post.comments.take(4).toList().asMap().entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CommentTile(
                          comment: entry.value,
                          onLike: () => widget.onLikeComment(entry.value.id),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            focusNode: _commentFocusNode,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _submitComment,
                            decoration: InputDecoration(
                              hintText: 'Escribe un comentario...',
                              filled: true,
                              fillColor: const Color(0xFFF7F3EC),
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
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () => _submitComment(_commentCtrl.text),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Enviar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitComment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    widget.onAddComment(trimmed);
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleCommentTap() async {
    if (!widget.post.commentsExpanded) {
      await widget.onToggleComments();
      if (!mounted) return;
    }

    _commentFocusNode.requestFocus();
  }

  Future<void> _toggleCommentsVisibility() async {
    await widget.onToggleComments();
    if (!mounted || widget.post.commentsExpanded) return;
    FocusScope.of(context).unfocus();
  }

  Future<void> _confirmDeletePost() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar post'),
          content: const Text('Este post se eliminará permanentemente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB74D2C),
              ),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await widget.onDelete();
    }
  }
}

class _FeedAvatar extends StatelessWidget {
  const _FeedAvatar({
    required this.photoUrl,
    required this.radius,
    required this.heroTag,
    required this.userName,
  });

  final String photoUrl;
  final double radius;
  final String heroTag;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final trimmed = photoUrl.trim();

    return GestureDetector(
      onTap: trimmed.isEmpty
          ? null
          : () => showDialog<void>(
              context: context,
              barrierColor: Colors.black.withValues(alpha: 0.82),
              builder: (context) => _AvatarPreviewDialog(
                photoUrl: trimmed,
                heroTag: heroTag,
                userName: userName,
              ),
            ),
      child: Hero(
        tag: heroTag,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFD9E7EE),
          backgroundImage: trimmed.isNotEmpty ? NetworkImage(trimmed) : null,
          child: trimmed.isEmpty
              ? const Icon(Icons.person, color: Color(0xFF35515E))
              : null,
        ),
      ),
    );
  }
}

class _AvatarPreviewDialog extends StatelessWidget {
  const _AvatarPreviewDialog({
    required this.photoUrl,
    required this.heroTag,
    required this.userName,
  });

  final String photoUrl;
  final String heroTag;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: heroTag,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD9E7EE),
                              image: DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 30,
                                  offset: Offset(0, 16),
                                  color: Color(0x33000000),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                    ),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
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

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.post});

  final DashboardSocialPost post;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: post.media.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _MediaCard(post: post, item: post.media[index], index: index);
        },
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.post,
    required this.item,
    required this.index,
  });

  final DashboardSocialPost post;
  final DashboardSocialMediaItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black12,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: item.isVideo
                ? _InlineVideoPlayer(item: item)
                : _ZoomableFeedImage(item: item),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.42),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${index + 1}/${post.media.length}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (item.isVideo)
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.videoDurationLabel ?? 'Video',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: (index + 1) / post.media.length,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    item.isVideo ? 'Clip' : 'Zoom',
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

class _ZoomableFeedImage extends StatelessWidget {
  const _ZoomableFeedImage({required this.item});

  final DashboardSocialMediaItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _FullscreenImageView(item: item),
            ),
          );
        },
        child: Ink.image(image: _mediaImageProvider(item), fit: BoxFit.cover),
      ),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.item});

  final DashboardSocialMediaItem item;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
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
      final controller = widget.item.isLocal
          ? VideoPlayerController.file(File(widget.item.source))
          : VideoPlayerController.networkUrl(
              Uri.parse(
                widget.item.remoteUrl.isNotEmpty
                    ? widget.item.remoteUrl
                    : widget.item.source,
              ),
            );
      await controller.initialize();

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.white,
          handleColor: Colors.white,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
        placeholder: _VideoThumbnail(item: widget.item),
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
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _VideoThumbnail(item: widget.item),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No se pudo cargar el video.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final chewie = _chewieController;
    if (chewie == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _VideoThumbnail(item: widget.item),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController?.value.aspectRatio ?? (16 / 9),
          child: Chewie(controller: chewie),
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.item});

  final DashboardSocialMediaItem item;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: _mediaImageProvider(item),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black26),
        ),
        Container(color: Colors.black.withValues(alpha: 0.24)),
        Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 42),
          ),
        ),
      ],
    );
  }
}

class _FullscreenImageView extends StatelessWidget {
  const _FullscreenImageView({required this.item});

  final DashboardSocialMediaItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: item.isLocal
                      ? Image.file(File(item.source), fit: BoxFit.contain)
                      : CachedNetworkImage(
                          imageUrl: item.source,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 64,
                          ),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                ),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ImageProvider _mediaImageProvider(DashboardSocialMediaItem item) {
  if (item.isLocal) {
    return FileImage(File(item.source));
  }

  return NetworkImage(item.source);
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onLike});

  final DashboardSocialComment comment;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = comment.authorAvatarUrl.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFD9E7EE),
          backgroundImage: avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 16, color: Color(0xFF35515E))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${comment.authorName} ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: comment.message),
                    TextSpan(
                      text: ' · ${comment.timeLabel}',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: comment.isLiked
                            ? const Color(0xFFE74C3C)
                            : Colors.black54,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        comment.likesCount > 0
                            ? '${comment.likesCount} like${comment.likesCount == 1 ? '' : 's'}'
                            : 'Like',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: comment.isLiked
                              ? const Color(0xFFE74C3C)
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
