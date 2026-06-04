import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppAnnouncement {
  const AppAnnouncement({
    required this.id,
    required this.type,
    required this.dismissible,
    this.title,
    this.body,
    this.imageUrl,
    this.videoUrl,
    this.ctaLabel,
    this.ctaUrl,
  });

  final String id;
  final String type;
  final bool dismissible;
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? videoUrl;
  final String? ctaLabel;
  final String? ctaUrl;

  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';

  bool get hasMedia {
    if (isVideo) return (videoUrl ?? '').trim().isNotEmpty;
    if (isImage) return (imageUrl ?? '').trim().isNotEmpty;
    return false;
  }

  bool get hasCta =>
      (ctaLabel ?? '').trim().isNotEmpty && (ctaUrl ?? '').trim().isNotEmpty;

  static AppAnnouncement? fromRemoteConfig(FirebaseRemoteConfig rc) {
    final enabled = rc.getBool('announcement_enabled');
    if (!enabled) return null;

    final id = rc.getString('announcement_id').trim();
    final type = rc.getString('announcement_type').trim().toLowerCase();

    if (id.isEmpty) return null;
    if (type != 'image' && type != 'video') return null;

    final announcement = AppAnnouncement(
      id: id,
      type: type,
      dismissible: rc.getBool('announcement_dismissible'),
      title: _readOptional(rc, 'announcement_title'),
      body: _readOptional(rc, 'announcement_body'),
      imageUrl: _readOptional(rc, 'announcement_image_url'),
      videoUrl: _readOptional(rc, 'announcement_video_url'),
      ctaLabel: _readOptional(rc, 'announcement_cta_label'),
      ctaUrl: _readOptional(rc, 'announcement_cta_url'),
    );

    return announcement.hasMedia ? announcement : null;
  }

  static String? _readOptional(FirebaseRemoteConfig rc, String key) {
    final value = rc.getString(key).trim();
    return value.isEmpty ? null : value;
  }
}
