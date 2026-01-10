import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/models/play_book_model.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_repository.dart';
import '../../../core/network/paginated_response.dart';

class PlayBookListController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs; // carga inicial / refresh
  final isLoadingMore = false.obs; // paginación
  final error = RxnString();

  final items = <PlaybookPlay>[].obs;

  final selectedType = RxnString(); // null = todos
  int _page = 1;
  bool _hasMore = true;

  late final ScrollController scrollCtrl;

  final userRole = 'player'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSession();
    scrollCtrl = ScrollController()..addListener(_onScroll);
    load(reset: true);
  }

  void _loadSession() {
    final user = AppStorage.getUser();
    userRole.value = user?.role ?? 'player';
  }

  @override
  void onClose() {
    scrollCtrl.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!_hasMore) return;
    if (isLoading.value || isLoadingMore.value) return;

    final pos = scrollCtrl.position;
    if (!pos.hasPixels) return;

    // cuando faltan ~300px para llegar al final, pide otra página
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      loadMore();
    }
  }

  Future<void> setType(String? type) async {
    selectedType.value = (type == null || type.isEmpty) ? null : type;
    await load(reset: true);
  }

  Future<void> load({required bool reset}) async {
    try {
      error.value = null;

      if (reset) {
        isLoading.value = true;
        _page = 1;
        _hasMore = true;
      } else {
        isLoadingMore.value = true;
      }

      final idCategory = AppStorage.getSelectedCategoryId();

      final PaginatedResponse<PlaybookPlay> res = await _api.getPlaybookPlays(
        categoryId: idCategory!,
        page: _page,
        type: selectedType.value,
      );

      if (reset) {
        items.assignAll(res.data);
      } else {
        items.addAll(res.data);
      }

      _hasMore = (res.nextPageUrl != null) && res.data.isNotEmpty;
      if (_hasMore) _page++;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshList() => load(reset: true);

  Future<void> loadMore() => load(reset: false);

  Future<void> goToCreate() async {
    final res = await Get.toNamed(Routes.playbookCreate);
    if (res is Map && res['refresh'] == true) {
      load(reset: true);
    }
  }

  Future<void> goToDetail(PlaybookPlay play) async {
    if (play.isAttachment && play.attachment?.url != null) {
      final url = play.attachment!.url;

      final uri = Uri.parse(url);

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        Get.snackbar(
          'Archivo',
          'No se pudo abrir el archivo',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    // ✅ SI ES GO → editor / lector
    if (userRole.value == "coach") {
      await Get.toNamed(Routes.playbook, arguments: {'playId': play.id});
    } else {
      await Get.toNamed(Routes.playbookRead, arguments: {'playId': play.id});
    }

    // refrescar lista al volver
    load(reset: true);
  }

  Future<bool> deletePlayOnBackend(String playId) async {
    try {
      final ok = await _api.playbookDeletePlay(playId: playId);
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> deletePlay(PlaybookPlay play) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Eliminar jugada'),
        content: Text('¿Seguro que quieres eliminar "${play.alias}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final deleted = await _api.playbookDeletePlay(playId: play.id);
      if (!deleted) throw Exception('No se pudo eliminar');

      // quítalo del listado al vuelo
      items.removeWhere((e) => e.id == play.id);
      items.refresh();

      Get.snackbar('Jugada', 'Eliminada', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'Jugada',
        'No se pudo eliminar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
