// game_media_models.dart
import 'dart:convert';

/// ===== INIT IMAGE =====
class InitImageUploadResponse {
  final String imageId;
  final String uploadURL;

  InitImageUploadResponse({required this.imageId, required this.uploadURL});

  factory InitImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return InitImageUploadResponse(
      imageId: (json['imageId'] ?? '').toString(),
      uploadURL: (json['uploadURL'] ?? '').toString(),
    );
  }
}

/// ===== INIT VIDEO =====
class InitVideoUploadResponse {
  final String uid;
  final String uploadURL;

  InitVideoUploadResponse({required this.uid, required this.uploadURL});

  factory InitVideoUploadResponse.fromJson(Map<String, dynamic> json) {
    return InitVideoUploadResponse(
      uid: (json['uid'] ?? '').toString(),
      uploadURL: (json['uploadURL'] ?? '').toString(),
    );
  }
}

/// ===== GALLERY RESPONSE =====
class GameGalleryResponse {
  final List<GameMediaItem> data;

  GameGalleryResponse({required this.data});

  factory GameGalleryResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List?) ?? const [];
    return GameGalleryResponse(
      data: list
          .map(
            (e) => GameMediaItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

enum GameMediaType { image, video, unknown }

enum GameMediaProvider {
  cloudflareImages,
  cloudflareStream,
  legacyLocal,
  unknown,
}

class GameMediaItem {
  final int id;
  final GameMediaType type;
  final GameMediaProvider provider;

  /// Para Images / Legacy
  final String? url;

  /// Para Cloudflare Images
  final String? cloudflareId;

  /// Para Cloudflare Stream
  final String? uid;
  final String? hls;
  final String? thumbnail;

  final int position;
  final Map<String, dynamic>? meta;
  final DateTime? createdAt;

  GameMediaItem({
    required this.id,
    required this.type,
    required this.provider,
    this.url,
    this.cloudflareId,
    this.uid,
    this.hls,
    this.thumbnail,
    required this.position,
    this.meta,
    this.createdAt,
  });

  factory GameMediaItem.fromJson(Map<String, dynamic> json) {
    GameMediaType parseType(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'image':
          return GameMediaType.image;
        case 'video':
          return GameMediaType.video;
        default:
          return GameMediaType.unknown;
      }
    }

    GameMediaProvider parseProvider(String? s) {
      final v = (s ?? '').toLowerCase();
      if (v == 'cloudflare_images') return GameMediaProvider.cloudflareImages;
      if (v == 'cloudflare_stream') return GameMediaProvider.cloudflareStream;
      if (v == 'legacy_local') return GameMediaProvider.legacyLocal;
      return GameMediaProvider.unknown;
    }

    DateTime? parseDate(dynamic v) {
      final str = v?.toString();
      if (str == null || str.isEmpty) return null;
      return DateTime.tryParse(str);
    }

    Map<String, dynamic>? parseMeta(dynamic v) {
      if (v == null) return null;
      if (v is Map) return Map<String, dynamic>.from(v as Map);
      // por si llega como string json
      if (v is String) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      return null;
    }

    return GameMediaItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: parseType(json['type']?.toString()),
      provider: parseProvider(json['provider']?.toString()),
      url: json['url']?.toString(),
      cloudflareId: json['cloudflare_id']?.toString(),
      uid: json['uid']?.toString(),
      hls: json['hls']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      position: (json['position'] as num?)?.toInt() ?? 0,
      meta: parseMeta(json['meta']),
      createdAt: parseDate(json['created_at']),
    );
  }

  bool get isImage => type == GameMediaType.image;
  bool get isVideo => type == GameMediaType.video;

  /// Unifica "displayUrl" para imágenes (cloudflare_images o legacy_local)
  String? get displayImageUrl => url;

  /// Para video: si no hay thumbnail, puedes usar un placeholder.
  String? get displayThumbnailUrl => thumbnail;

  /// Para video: HLS manifest
  String? get hlsUrl => hls;
}
