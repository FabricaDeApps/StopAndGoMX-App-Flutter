import 'package:get/get.dart';
import 'package:stopandgo/core/network/game_gallery_repository.dart';
import 'package:stopandgo/core/services/app_usage_session_service.dart';
import 'package:stopandgo/core/services/coach_games_service.dart';
import 'package:stopandgo/core/services/coach_trainings_service.dart';
import 'package:stopandgo/core/services/ecommerce_cart_service.dart';
import 'package:stopandgo/core/services/manager_games_service.dart';
import 'package:stopandgo/core/services/manager_trainings_service.dart';
import '../core/network/api_repository.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Registra el repositorio principal para toda la app
    if (!Get.isRegistered<ApiRepository>()) {
      Get.put(ApiRepository(), permanent: true);
      Get.put(GameGalleryRepository(), permanent: true);
    }

    if (!Get.isRegistered<EcommerceCartService>()) {
      Get.put<EcommerceCartService>(EcommerceCartService(), permanent: true);
    }

    if (!Get.isRegistered<ManagerGamesService>()) {
      Get.put<ManagerGamesService>(ManagerGamesService(), permanent: true);
    }

    if (!Get.isRegistered<ManagerTrainingsService>()) {
      Get.put<ManagerTrainingsService>(
        ManagerTrainingsService(),
        permanent: true,
      );
    }

    if (!Get.isRegistered<CoachGamesService>()) {
      Get.put<CoachGamesService>(CoachGamesService(), permanent: true);
    }

    if (!Get.isRegistered<CoachTrainingsService>()) {
      Get.put<CoachTrainingsService>(CoachTrainingsService(), permanent: true);
    }

    if (!Get.isRegistered<AppUsageSessionService>()) {
      Get.putAsync<AppUsageSessionService>(
        () async => AppUsageSessionService().init(),
        permanent: true,
      );
    }
  }
}
