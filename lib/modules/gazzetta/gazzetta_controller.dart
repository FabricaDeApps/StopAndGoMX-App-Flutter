import 'package:get/get.dart';
import 'package:stopandgo/core/models/gazzetta/gazzetta_models.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/network/gazzetta_exceptions.dart';
import 'package:stopandgo/core/network/paginated_response.dart';

class GazzettaController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isModuleUnavailable = false.obs;
  final error = RxnString();

  final feed = Rxn<GazettaDetail>();
  final history = <GazettaItem>[].obs;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasNextPage = false;

  bool get canLoadMore =>
      _hasNextPage && !isLoading.value && !isLoadingMore.value;

  Future<void> refreshData() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = null;
    isModuleUnavailable.value = false;
    feed.value = null;
    history.clear();
    _currentPage = 1;
    _lastPage = 1;
    _hasNextPage = false;

    try {
      final result = await Future.wait<dynamic>([
        _api.getGazettaFeed(),
        _api.getGazettaHistory(page: 1, perPage: 20),
      ]);

      feed.value = result[0] as GazettaDetail?;
      final paginated = result[1] as PaginatedResponse<GazettaItem>;
      history.assignAll(paginated.data);
      _currentPage = paginated.currentPage;
      _lastPage = paginated.lastPage ?? _currentPage;
      _hasNextPage = paginated.nextPageUrl != null && _currentPage < _lastPage;
    } on GazettaModuleUnavailableException {
      isModuleUnavailable.value = true;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!canLoadMore) return;
    isLoadingMore.value = true;

    try {
      final nextPage = _currentPage + 1;
      final page = await _api.getGazettaHistory(page: nextPage, perPage: 20);
      history.addAll(page.data);
      _currentPage = page.currentPage;
      _lastPage = page.lastPage ?? _currentPage;
      _hasNextPage = page.nextPageUrl != null && _currentPage < _lastPage;
    } on GazettaModuleUnavailableException {
      isModuleUnavailable.value = true;
    } catch (_) {
      // No interrumpimos el listado si falla la paginación incremental.
    } finally {
      isLoadingMore.value = false;
    }
  }
}
