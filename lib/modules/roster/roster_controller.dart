import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class RosterController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();
  final players = <Player>[].obs;

  late final int categoryId;
  late final String categoryName;

  @override
  void onInit() {
    super.onInit();
    categoryId = AppStorage.getSelectedCategoryId() ?? 0;
    categoryName = AppStorage.getSelectedCategoryName() ?? "";
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _api.getGamePlayers(categoryId: categoryId);
      players.assignAll(result);
    } catch (e) {
      error.value = 'No se pudieron cargar los jugadores.';
      Get.snackbar(
        'Roster',
        'No se pudieron cargar jugadores: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPlayers() => _loadPlayers();

  Future<void> updatePlayerPhoto(Player player) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image == null) return;

      isLoading.value = true;

      await _api.updatePlayerPhoto(
        categoryId: categoryId,
        playerId: player.id,
        filePath: image.path,
      );

      // Opcional: recargar lista para que se vea la foto nueva
      await _loadPlayers();

      Get.snackbar(
        'Foto actualizada',
        'La foto de ${player.name} se actualizó correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo actualizar la foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
