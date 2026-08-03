import 'package:get/get.dart';

import 'recompensas_coach_score_entry_controller.dart';

class RecompensasCoachScoreEntryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecompensasCoachScoreEntryController>(
      () => RecompensasCoachScoreEntryController(),
    );
  }
}
