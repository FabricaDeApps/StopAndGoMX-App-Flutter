import 'package:get/get.dart';
import 'package:stopandgo/core/theme/app_theme.dart';

class ThemeController extends GetxController {
  final theme = AppTheme.light.obs;

  void refreshTheme() {
    theme.value = AppTheme.light;
  }
}
