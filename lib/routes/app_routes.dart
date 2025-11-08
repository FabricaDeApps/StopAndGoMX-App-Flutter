import 'package:get/get.dart';
import 'package:stopandgo/modules/auth/login_binding.dart';
import 'package:stopandgo/modules/auth/login_view.dart';
import 'package:stopandgo/modules/home/index.dart';
import 'package:stopandgo/modules/image_view/image_binding.dart';
import 'package:stopandgo/modules/image_view/image_view.dart';
import 'package:stopandgo/modules/make_payment/index.dart';
import 'package:stopandgo/modules/make_payment/make_payment_view.dart';
import 'package:stopandgo/modules/splash/splash_binding.dart';
import 'package:stopandgo/modules/splash/splash_view.dart';
import '../modules/home/home_view.dart';
import '../modules/home/home_controller.dart';

part 'app_routes_names.dart';

class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.notices,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.makePayment,
      page: () => const MakePaymentView(),
      binding: MakePaymentBinding(),
    ),
    GetPage(
      name: Routes.imageView,
      page: () => const ImageView(),
      binding: ImageBinding(),
    ),

    // Ejemplo de futuras pantallas:
    // GetPage(
    //   name: Routes.login,
    //   page: () => const LoginView(),
    //   binding: LoginBinding(),
    // ),
  ];
}
