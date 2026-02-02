import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/models/games/game_media_models.dart';
import 'package:stopandgo/core/network/api_client.dart';
import 'package:stopandgo/core/network/token_storage.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class GameGalleryRepository {
  final Dio _dio = ApiClient.dio;
  final TokenStorage _tokenStorage = Get.find<TokenStorage>();

  ////////

  String? get _accessToken => _tokenStorage.accessToken;
  String get _tokenType => _tokenStorage.tokenType!;

  Map<String, dynamic> get _authHeader => _accessToken == null
      ? {}
      : {'Authorization': '$_tokenType $_accessToken'};

  Map<String, dynamic> get _orgHeader {
    final org = AppStorage.getOrganization();
    return org == null ? {} : {'X-Organization-Id': org.id.toString()};
  }

  Map<String, dynamic> _headers([Map<String, dynamic>? extra]) => {
    ..._authHeader,
    ..._orgHeader,
    'Accept': 'application/json',
    if (extra != null) ...extra,
  };

  Options _options() => Options(
    headers: _headers(),
    validateStatus: (code) => code != null && code >= 200 && code < 500,
  );

  // =========================
  // GALLERY
  // =========================
  Future<List<GameMediaItem>> fetchGallery(int gameId) async {
    try {
      final res = await _dio.get('/games/$gameId/gallery', options: _options());

      if (res.statusCode == 200 && res.data is Map) {
        final parsed = GameGalleryResponse.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
        return parsed.data;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // =========================
  // IMAGES
  // =========================
  Future<InitImageUploadResponse?> initImage(int gameId) async {
    try {
      final res = await _dio.post(
        '/games/$gameId/images/init',
        options: _options(),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
        return InitImageUploadResponse.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<GameMediaItem?> confirmImage({
    required int gameId,
    required String imageId,
  }) async {
    try {
      final res = await _dio.post(
        '/games/$gameId/images/confirm',
        data: {'imageId': imageId},
        options: _options(),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
        return GameMediaItem.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================
  // VIDEOS
  // =========================
  Future<InitVideoUploadResponse?> initVideo(int gameId) async {
    try {
      final res = await _dio.post(
        '/games/$gameId/videos/init',
        options: _options(),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
        return InitVideoUploadResponse.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<GameMediaItem?> confirmVideo({
    required int gameId,
    required String uid,
  }) async {
    try {
      final res = await _dio.post(
        '/games/$gameId/videos/confirm',
        data: {'uid': uid},
        options: _options(),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
        return GameMediaItem.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================
  // UPLOAD DIRECTO A CLOUDFLARE
  // (sin headers de auth)
  // =========================
  Future<bool> uploadToCloudflare({
    required String uploadUrl,
    required XFile file,
    ProgressCallback? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });

      final res = await _dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
        onSendProgress: onProgress,
      );

      return res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // HELPERS
  // =========================
  Future<List<GameMediaItem>> uploadMultipleImages({
    required int gameId,
    required List<XFile> files,
    void Function(int index, int sent, int total)? onProgress,
  }) async {
    final List<GameMediaItem> result = [];

    for (int i = 0; i < files.length; i++) {
      final init = await initImage(gameId);
      if (init == null) continue;

      final ok = await uploadToCloudflare(
        uploadUrl: init.uploadURL,
        file: files[i],
        onProgress: (s, t) {
          if (onProgress != null) onProgress(i, s, t);
        },
      );

      if (!ok) continue;

      final confirmed = await confirmImage(
        gameId: gameId,
        imageId: init.imageId,
      );

      if (confirmed != null) result.add(confirmed);
    }

    return result;
  }

  Future<GameMediaItem?> uploadSingleVideo({
    required int gameId,
    required XFile file,
    ProgressCallback? onProgress,
  }) async {
    final init = await initVideo(gameId);
    if (init == null) return null;

    final ok = await uploadToCloudflare(
      uploadUrl: init.uploadURL,
      file: file,
      onProgress: onProgress,
    );

    if (!ok) return null;

    return await confirmVideo(gameId: gameId, uid: init.uid);
  }
}
