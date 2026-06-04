import 'dart:io';

import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/models/attendance_dashboard.dart';
import 'package:stopandgo/core/models/dashboard_models.dart';
import 'package:stopandgo/core/models/dto/notice_model.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/role_utils.dart';
import 'package:stopandgo/modules/home/home_controller.dart';
import 'package:stopandgo/modules/home/tabs/dashboard/models/dashboard_social_post.dart';
import 'package:video_player/video_player.dart';

class DashboardTabController extends GetxController {
  final api = Get.find<ApiRepository>();

  bool get isSocialModuleEnabled =>
      AppStorage.getOrganization()?.socialModule == true;

  // Inputs (los setea HomeController)
  final role = ''.obs; // manager/coach/staff/parent/player
  final selectedCategoryId = RxnInt();
  final selectedPlayerId = RxnInt();

  // Outputs (UI)
  final isLoading = false.obs;
  final saldoPendiente = 0.0.obs;
  final pagosRealizados = 0.0.obs;
  final upcomingGames = <Game>[].obs;
  final notices = <Notice>[].obs;
  final playerCategories = <PlayerDashboardCategory>[].obs;
  final attendance = AttendanceDashboard.empty.obs;
  final socialPosts = <DashboardSocialPost>[].obs;

  void setContext({required String userRole, int? categoryId, int? playerId}) {
    role.value = userRole;
    selectedCategoryId.value = categoryId;
    selectedPlayerId.value = playerId;
  }

  @override
  Future<void> refresh() async {
    if (hasManagerPrivileges(role.value)) {
      await _loadDashboardForManager();
    } else {
      switch (role.value) {
        case 'coach':
          await _loadDashboardForCoach();
          break;
        case 'staff':
          await _loadDashboardForStaff();
          break;
        case 'parent':
        case 'player':
        default:
          await _loadDashboardForPlayerOrParent();
          break;
      }
    }

    await _loadSocialFeed();
  }

  // ---------------- MANAGER ----------------
  Future<void> _loadDashboardForManager() async {
    try {
      isLoading.value = true;
      final dash = await api.getManagerDashboard();
      _mapManagerDashboard(dash);
    } catch (e) {
      Get.snackbar(
        'Dashboard',
        'No se pudo cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _mapManagerDashboard(ManagerDashboardResponse dash) {
    saldoPendiente.value = 0.0;
    pagosRealizados.value = 0.0;
    upcomingGames.assignAll(_sortedByStart(dash.nextGames));
    _setSingleNotice(dash.lastNotice);
  }

  // ---------------- STAFF ----------------
  Future<void> _loadDashboardForStaff() async {
    try {
      isLoading.value = true;
      final dash = await api.getStaffDashboard();
      _mapStaffDashboard(dash);
    } catch (e) {
      Get.snackbar(
        'Dashboard',
        'No se pudo cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _mapStaffDashboard(StaffDashboard dash) {
    saldoPendiente.value = 0.0;
    pagosRealizados.value = 0.0;

    final sorted = _sortedByStart(List<Game>.from(dash.upcomingGames));
    upcomingGames.assignAll(sorted.take(3).toList());
    _setSingleNotice(dash.lastNotice);
  }

  // ---------------- COACH ----------------
  Future<void> _loadDashboardForCoach() async {
    try {
      isLoading.value = true;
      final categoryId =
          selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
      if (categoryId == null) return;
      final dash = await api.getCoachDashboard();
      _mapCoachDashboard(dash);
    } catch (e) {
      Get.snackbar(
        'Dashboard',
        'No se pudo cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _mapCoachDashboard(ParentDashboardResponse dash) {
    saldoPendiente.value = 0.0;
    pagosRealizados.value = 0.0;

    final all = <Game>[];
    for (final child in dash.children) {
      all.addAll(child.upcomingGames);
    }

    final sorted = _sortedByStart(all);
    upcomingGames.assignAll(sorted.take(3).toList());
    _setSingleNotice(dash.lastNotice);
  }

  // ---------------- PLAYER/PARENT ----------------
  Future<void> _loadDashboardForPlayerOrParent() async {
    try {
      isLoading.value = true;

      if (role.value == 'player') {
        final dash = await api.getPlayerDashboard();
        _mapPlayerDashboard(dash);
      } else if (role.value == 'parent') {
        final dash = await api.getParentDashboard();
        _mapParentDashboard(dash);
      } else {
        // fallback viejo
        final json = await api.playerHomeDashboard();
        _mapPlayerHomeJson(json);
      }
    } catch (e) {
      Get.snackbar(
        'Dashboard',
        'No se pudo cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _mapPlayerDashboard(PlayerDashboardResponse dash) {
    saldoPendiente.value = dash.pendingTotal;
    pagosRealizados.value = 0.0;

    final games = dash.categories
        .map((c) => c.nextGame)
        .whereType<Game>()
        .toList();

    final sorted = _sortedByStart(games);
    playerCategories.clear();
    upcomingGames.clear();

    upcomingGames.assignAll(sorted.take(3).toList());
    playerCategories.assignAll(dash.categories);
    attendance.value = dash.attendance;

    _setSingleNotice(dash.lastNotice);
  }

  void _mapParentDashboard(ParentDashboardResponse dash) {
    saldoPendiente.value = dash.pendingTotal;
    pagosRealizados.value = 0.0;

    final all = <Game>[];
    for (final child in dash.children) {
      all.addAll(child.upcomingGames);
    }

    final sorted = _sortedByStart(all);
    upcomingGames.assignAll(sorted.take(3).toList());
    _setSingleNotice(dash.lastNotice);
  }

  // ---------------- Helpers ----------------
  void _setSingleNotice(dynamic n) {
    notices.clear();
    if (n == null) return;

    DateTime date = DateTime.now();
    try {
      final published = n.publishedAt;
      final created = n.createdAt;

      if (published is DateTime) {
        date = published;
      } else if (published is String) {
        date = DateTime.tryParse(published) ?? date;
      } else if (created is DateTime) {
        date = created;
      } else if (created is String) {
        date = DateTime.tryParse(created) ?? date;
      }
    } catch (_) {}

    notices.add(
      Notice(
        id: (n.id as int),
        title: (n.title as String),
        message: n.message?.toString(),
        image: n.image?.toString(),
        attachment: n.attachment?.toString(),
        externalUrl: n.externalUrl?.toString(),
        publishedAt: date,
        organizationId: 0,
        isPublished: true,
      ),
    );
  }

  List<Game> _sortedByStart(List<Game> list) {
    final copy = [...list];
    copy.sort((a, b) {
      final da = a.startsAt ?? DateTime(2100);
      final db = b.startsAt ?? DateTime(2100);
      return da.compareTo(db);
    });
    return copy;
  }

  void _mapPlayerHomeJson(Map<String, dynamic> json) {
    final payments = (json['payments'] ?? {}) as Map<String, dynamic>;
    final items = (payments['items'] as List?) ?? const [];

    double totalPagado = 0.0;
    double totalAdeudo = 0.0;

    for (final raw in items) {
      final m = raw as Map<String, dynamic>;
      final amount = (m['amount'] ?? 0).toDouble();
      final receipts = (m['receipts'] as List?) ?? const [];
      double pagado = 0.0;
      for (final r in receipts) {
        pagado += ((r as Map<String, dynamic>)['amount'] ?? 0).toDouble();
      }
      totalPagado += pagado;
      final balance = (amount - pagado);
      if (balance > 0) totalAdeudo += balance;
    }

    pagosRealizados.value = totalPagado;
    saldoPendiente.value = totalAdeudo;

    final gamesJson =
        ((json['games'] ?? {}) as Map<String, dynamic>)['items'] as List? ??
        const [];
    final games = gamesJson.map((g) => Game.fromJson(g)).toList();
    upcomingGames.assignAll(_sortedByStart(games).take(3).toList());

    notices.clear();
    if (json['last_notice'] != null) {
      final n = json['last_notice'] as Map<String, dynamic>;
      notices.add(
        Notice(
          id: (n['id'] ?? 0) as int,
          title: (n['title'] ?? '') as String,
          message: n['message']?.toString(),
          image: n['image']?.toString(),
          attachment: n['attachment']?.toString(),
          externalUrl: n['external_url']?.toString(),
          publishedAt:
              DateTime.tryParse(
                (n['published_at'] ?? n['created_at'] ?? '').toString(),
              ) ??
              DateTime.now(),
          organizationId: 0,
          isPublished: true,
        ),
      );
    }
  }

  Future<void> _loadSocialFeed() async {
    if (!isSocialModuleEnabled) {
      socialPosts.clear();
      return;
    }

    try {
      final posts = await api.getSocialFeed();
      socialPosts.assignAll(posts);
    } catch (e) {
      Get.snackbar(
        'Feed social',
        'No se pudo cargar el feed: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<List<DashboardMentionableUser>> searchMentionableUsers(
    String query,
  ) async {
    try {
      return await api.searchMentionableUsers(query: query);
    } catch (_) {
      return const [];
    }
  }

  Future<void> toggleLikePost(int postId) async {
    final index = socialPosts.indexWhere((post) => post.id == postId);
    if (index < 0) return;

    final current = socialPosts[index];
    final nextLiked = !current.isLiked;
    socialPosts[index] = current.copyWith(
      isLiked: nextLiked,
      likesCount: current.likesCount + (nextLiked ? 1 : -1),
    );

    final response = await api.toggleSocialPostLike(postId: postId);
    if (response == null) {
      socialPosts[index] = current;
      return;
    }

    socialPosts[index] = socialPosts[index].copyWith(
      isLiked: response['is_liked'] == true,
      likesCount: (response['likes_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> toggleComments(int postId) async {
    final index = socialPosts.indexWhere((post) => post.id == postId);
    if (index < 0) return;

    final current = socialPosts[index];
    if (current.commentsExpanded) {
      socialPosts[index] = current.copyWith(commentsExpanded: false);
      return;
    }

    try {
      final detail = await api.getSocialPostDetail(postId);
      socialPosts[index] = detail.copyWith(commentsExpanded: true);
    } catch (_) {
      socialPosts[index] = current.copyWith(commentsExpanded: true);
    }
  }

  Future<void> addCommentToPost(int postId, String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final index = socialPosts.indexWhere((post) => post.id == postId);
    if (index < 0) return;

    try {
      final created = await api.createSocialComment(
        postId: postId,
        message: trimmed,
      );

      final current = socialPosts[index];
      socialPosts[index] = current.copyWith(
        commentsExpanded: true,
        comments: [...current.comments, created],
        commentsCount: current.commentsCount + 1,
      );
    } catch (e) {
      Get.snackbar(
        'Comentarios',
        'No se pudo agregar el comentario: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deletePost(int postId) async {
    final index = socialPosts.indexWhere((post) => post.id == postId);
    if (index < 0) return;

    final removed = socialPosts[index];
    socialPosts.removeAt(index);

    final ok = await api.deleteSocialPost(postId: postId);
    if (!ok) {
      socialPosts.insert(index, removed);
      Get.snackbar(
        'Feed social',
        'No se pudo borrar el post.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> toggleLikeComment(int postId, int commentId) async {
    final postIndex = socialPosts.indexWhere((post) => post.id == postId);
    if (postIndex < 0) return;

    final currentPost = socialPosts[postIndex];
    final commentIndex = currentPost.comments.indexWhere(
      (c) => c.id == commentId,
    );
    if (commentIndex < 0) return;

    final nextComments = List<DashboardSocialComment>.from(
      currentPost.comments,
    );
    final currentComment = nextComments[commentIndex];
    final nextLiked = !currentComment.isLiked;

    nextComments[commentIndex] = currentComment.copyWith(
      isLiked: nextLiked,
      likesCount: currentComment.likesCount + (nextLiked ? 1 : -1),
    );

    socialPosts[postIndex] = currentPost.copyWith(comments: nextComments);

    final response = await api.toggleSocialCommentLike(commentId: commentId);
    if (response == null) {
      socialPosts[postIndex] = currentPost;
      return;
    }

    final refreshed = List<DashboardSocialComment>.from(
      socialPosts[postIndex].comments,
    );
    refreshed[commentIndex] = refreshed[commentIndex].copyWith(
      isLiked: response['is_liked'] == true,
      likesCount: (response['likes_count'] as num?)?.toInt() ?? 0,
    );
    socialPosts[postIndex] = socialPosts[postIndex].copyWith(
      comments: refreshed,
    );
  }

  Future<void> createSocialPost({
    required String caption,
    required List<DashboardSocialMediaItem> media,
    List<DashboardMentionableUser> mentions = const [],
  }) async {
    final homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    final user = AppStorage.getUser();
    if (user == null) return;

    try {
      final created = await api.createSocialPost(
        caption: caption.trim(),
        mentionIds: mentions.map((e) => e.id).toList(),
      );

      final optimistic = created.copyWith(
        authorAvatarUrl: (homeCtrl?.userAvatar.value ?? user.photoUrl ?? '')
            .trim(),
        commentsExpanded: false,
      );
      socialPosts.insert(0, optimistic);

      if (media.isNotEmpty) {
        await _uploadMediaForPost(postId: created.id, media: media);
      }

      final detail = await api.getSocialPostDetail(created.id);
      _upsertSocialPost(detail);
      await _loadSocialFeed();
    } catch (e) {
      Get.snackbar(
        'Feed social',
        'No se pudo publicar el post: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> _uploadMediaForPost({
    required int postId,
    required List<DashboardSocialMediaItem> media,
  }) async {
    for (var i = 0; i < media.length; i++) {
      final item = media[i];
      if (!item.isLocal) continue;

      final file = XFile(item.source);
      if (item.type == DashboardSocialMediaType.image) {
        final init = await api.initSocialImageUpload(postId);
        if (init == null) continue;

        final ok = await api.uploadFileToCloudflare(
          uploadUrl: (init['uploadURL'] ?? '').toString(),
          file: file,
        );
        if (!ok) continue;

        final imageSize = _readImageSize(file.path);
        await api.confirmSocialImageUpload(
          postId: postId,
          imageId: (init['imageId'] ?? '').toString(),
          position: i,
          width: imageSize?.$1,
          height: imageSize?.$2,
        );
        continue;
      }

      final init = await api.initSocialVideoUpload(postId);
      if (init == null) continue;

      final ok = await api.uploadFileToCloudflare(
        uploadUrl: (init['uploadURL'] ?? '').toString(),
        file: file,
      );
      if (!ok) continue;

      final videoMeta = await _readVideoMeta(file.path);
      await api.confirmSocialVideoUpload(
        postId: postId,
        uid: (init['uid'] ?? '').toString(),
        position: i,
        width: videoMeta?.$1,
        height: videoMeta?.$2,
        durationSeconds: videoMeta?.$3,
      );
    }
  }

  (int, int)? _readImageSize(String path) {
    try {
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return (decoded.width, decoded.height);
    } catch (_) {
      return null;
    }
  }

  Future<(int, int, int)?> _readVideoMeta(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final size = controller.value.size;
      return (
        size.width.round(),
        size.height.round(),
        controller.value.duration.inSeconds,
      );
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  void _upsertSocialPost(DashboardSocialPost post) {
    final index = socialPosts.indexWhere((item) => item.id == post.id);
    if (index >= 0) {
      final expanded = socialPosts[index].commentsExpanded;
      socialPosts[index] = post.copyWith(commentsExpanded: expanded);
    } else {
      socialPosts.insert(0, post);
    }
  }
}
