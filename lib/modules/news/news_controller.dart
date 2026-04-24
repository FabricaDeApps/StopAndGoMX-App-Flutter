import 'package:get/get.dart';
import 'package:stopandgo/core/models/news/news_models.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class NewsController extends GetxController {
  final _api = Get.find<ApiRepository>();

  static const _pageSize = 15;

  final isLoading = false.obs;
  final isRefreshingFilters = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();

  final preferences = Rxn<NewsPreferences>();
  final items = <NewsItem>[].obs;
  final selectedSports = <String>[].obs;
  final effectiveSports = <String>[].obs;

  int _currentPage = 1;
  int _lastPage = 1;

  bool get canLoadMore =>
      _currentPage < _lastPage && !isLoading.value && !isLoadingMore.value;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = null;
    items.clear();
    _currentPage = 1;
    _lastPage = 1;

    try {
      final prefs = await _api.getNewsPreferences();
      preferences.value = prefs;

      if (selectedSports.isEmpty) {
        selectedSports.assignAll(
          prefs.sports.where((e) => e.isEnabled).map((e) => e.sport),
        );
      }

      await _loadPage(reset: true);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleSport(String sport) async {
    final next = selectedSports.toList();
    if (next.contains(sport)) {
      next.remove(sport);
    } else {
      next.add(sport);
    }

    selectedSports.assignAll(next);
    isRefreshingFilters.value = true;
    error.value = null;

    try {
      await _loadPage(reset: true);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isRefreshingFilters.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!canLoadMore) return;
    isLoadingMore.value = true;

    try {
      await _loadPage(page: _currentPage + 1);
    } catch (_) {
      // Dejamos la lista actual visible si falla la paginación incremental.
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> markAsSeen(NewsItem item) async {
    if (item.isSeen) return;

    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx < 0) return;

    final updated = item.copyWith(seenAt: DateTime.now(), isSeen: true);
    items[idx] = updated;

    try {
      await _api.markNewsSeen(item.id);
    } catch (_) {
      items[idx] = item;
    }
  }

  Future<void> _loadPage({bool reset = false, int page = 1}) async {
    final response = await _api.getNewsFeed(
      sports: selectedSports.isEmpty ? null : selectedSports,
      perPage: _pageSize,
      page: page,
    );

    effectiveSports.assignAll(response.meta.sports);
    _currentPage = response.meta.currentPage;
    _lastPage = response.meta.lastPage;

    if (reset) {
      items.assignAll(response.data);
      return;
    }

    items.addAll(response.data);
  }
}
