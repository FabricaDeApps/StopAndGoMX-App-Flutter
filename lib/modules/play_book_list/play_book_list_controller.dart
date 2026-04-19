import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/models/play_book_model.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/network/api_repository.dart';
import '../../../core/network/paginated_response.dart';

class PlayBookListController extends GetxController {
  final _api = Get.find<ApiRepository>();
  static const String filterPass = 'pass';
  static const String filterRun = 'run';
  static const String filterBlitz = 'blitz';
  static const String filterCoverage = 'coverage';

  final isLoading = false.obs; // carga inicial / refresh
  final isLoadingMore = false.obs; // paginación
  final error = RxnString();

  final items = <PlaybookPlay>[].obs;

  final selectedType = RxnString(); // null = todos
  int _page = 1;
  bool _hasMore = true;

  late final ScrollController scrollCtrl;

  final userRole = 'player'.obs;

  int? get selectedCategoryId => AppStorage.getSelectedCategoryId();

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
    selectedType.value = _normalizeType(type);
    await load(reset: true);
  }

  String? _normalizeType(String? type) {
    final value = type?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;

    switch (value) {
      case 'pass':
      case 'pase':
        return filterPass;
      case 'run':
      case 'carrera':
        return filterRun;
      case 'blitz':
        return filterBlitz;
      case 'coverage':
      case 'cobertura':
        return filterCoverage;
      default:
        return value;
    }
  }

  String typeLabel(String rawType) {
    switch (_normalizeType(rawType)) {
      case filterPass:
        return 'Pase';
      case filterRun:
        return 'Carrera';
      case filterBlitz:
        return 'Blitz';
      case filterCoverage:
        return 'Cobertura';
      default:
        return rawType.trim().isEmpty ? '-' : rawType;
    }
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
    await Get.toNamed(Routes.playbookRead, arguments: {'playId': play.id});
    await load(reset: true);
  }

  Future<void> goToReadDetail(PlaybookPlay play) async {
    await Get.toNamed(Routes.playbookRead, arguments: {'playId': play.id});
    await load(reset: true);
  }

  Future<void> goToEdit(PlaybookPlay play) async {
    if (!play.isGo) return;
    await Get.toNamed(Routes.playbook, arguments: {'playId': play.id});
    await load(reset: true);
  }

  Future<void> sharePlay(PlaybookPlay play) async {
    try {
      final categories = await _api.getPlaybookCategories();
      final options = categories
          .where((e) => e.id != play.categoryId)
          .where((e) => !play.sharedCategories.any((s) => s.id == e.id))
          .toList();

      if (options.isEmpty) {
        Get.snackbar(
          'Compartir jugada',
          'No hay categorías nuevas disponibles para compartir.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final selected = <int>{};
      final result = await Get.dialog<List<int>>(
        StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Compartir "${play.alias}"'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((category) {
                      final isSelected = selected.contains(category.id);
                      return CheckboxListTile(
                        value: isSelected,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(category.name),
                        subtitle: category.code?.isNotEmpty == true
                            ? Text(category.code!)
                            : null,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selected.add(category.id);
                            } else {
                              selected.remove(category.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: null),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Get.back(result: selected.toList()),
                  child: const Text('Compartir'),
                ),
              ],
            );
          },
        ),
      );

      if (result == null || result.isEmpty) return;

      await _api.playbookSharePlay(playId: play.id, categoryIds: result);
      Get.snackbar(
        'Compartir jugada',
        'Jugada compartida con ${result.length} categor${result.length == 1 ? 'ía' : 'ías'}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await load(reset: true);
    } catch (e) {
      Get.snackbar(
        'Compartir jugada',
        'No se pudo compartir: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
