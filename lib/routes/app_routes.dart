import 'package:get/get.dart';
import 'package:stopandgo/core/models/player_document.dart';
import 'package:stopandgo/modules/assign_player/index.dart';
import 'package:stopandgo/modules/attendece_game/index.dart';
import 'package:stopandgo/modules/auth/login_binding.dart';
import 'package:stopandgo/modules/auth/login_view.dart';
import 'package:stopandgo/modules/complete_game/complete_game_binding.dart';
import 'package:stopandgo/modules/complete_game/complete_game_view.dart';
import 'package:stopandgo/modules/create_trainning/index.dart';
import 'package:stopandgo/modules/home/index.dart';
import 'package:stopandgo/modules/image_view/image_binding.dart';
import 'package:stopandgo/modules/image_view/image_view.dart';
import 'package:stopandgo/modules/make_payment/index.dart';
import 'package:stopandgo/modules/my_profile/index.dart';
import 'package:stopandgo/modules/my_profile/my_profile_view.dart';
import 'package:stopandgo/modules/new_game/index.dart';
import 'package:stopandgo/modules/no_category/index.dart';
import 'package:stopandgo/modules/no_category/no_category_view.dart';
import 'package:stopandgo/modules/play_book/index.dart';
import 'package:stopandgo/modules/play_book/play_book_view.dart';
import 'package:stopandgo/modules/play_book_list/index.dart';
import 'package:stopandgo/modules/play_book_list/play_book_list_view.dart';
import 'package:stopandgo/modules/play_book_read/index.dart';
import 'package:stopandgo/modules/play_book_read/play_book_read_view.dart';
import 'package:stopandgo/modules/player_documents/player_documents_binding.dart';
import 'package:stopandgo/modules/player_documents/player_documents_view.dart';
import 'package:stopandgo/modules/roster/roster_binding.dart';
import 'package:stopandgo/modules/roster/roster_view.dart';
import 'package:stopandgo/modules/sign_in/sign_in_binding.dart';
import 'package:stopandgo/modules/sign_in/sign_in_view.dart';
import 'package:stopandgo/modules/splash/splash_binding.dart';
import 'package:stopandgo/modules/splash/splash_view.dart';
import 'package:stopandgo/modules/training_attendance/index.dart';
import 'package:stopandgo/modules/training_attendance/training_attendance_view.dart';
import 'package:stopandgo/modules/trainnings/index.dart';

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
    GetPage(
      name: Routes.newGame,
      page: () => const NewGameView(),
      binding: NewGameBinding(),
    ),
    GetPage(
      name: Routes.completeGame,
      page: () => const CompleteGameView(),
      binding: CompleteGameBinding(),
    ),
    GetPage(
      name: Routes.attendanceGame,
      page: () => const AttendanceGameView(),
      binding: AttendeceGameBinding(),
    ),
    GetPage(
      name: Routes.signIn,
      page: () => const SignInView(),
      binding: SignInBinding(),
    ),
    GetPage(
      name: Routes.trainnings,
      page: () => const TrainingsView(),
      binding: TrainningsBinding(),
    ),
    GetPage(
      name: Routes.createTrainnig,
      page: () => const CreateTrainningView(),
      binding: CreateTrainningBinding(),
    ),
    GetPage(
      name: Routes.assignPlayer,
      page: () => const AssignPlayerView(),
      binding: AssignPlayerBinding(),
    ),
    GetPage(
      name: Routes.trainingAttendance,
      page: () => const TrainingAttendanceView(),
      binding: TrainingAttendanceBinding(),
    ),
    GetPage(
      name: Routes.myProfile,
      page: () => const MyProfileView(),
      binding: MyProfileBinding(),
    ),
    GetPage(
      name: Routes.noCategory,
      page: () => const NoCategoryView(),
      binding: NoCategoryBinding(),
    ),
    GetPage(
      name: Routes.roster,
      page: () => const RosterView(),
      binding: RosterBinding(),
    ),
    GetPage(
      name: Routes.documents,
      page: () => const PlayerDocumentsView(),
      binding: PlayerDocumentsBinding(),
    ),
    GetPage(
      name: Routes.playbook,
      page: () => const PlayBookView(),
      binding: PlayBookBinding(),
    ),
    GetPage(
      name: Routes.playbookList,
      page: () => const PlayBookListView(),
      binding: PlayBookListBinding(),
    ),
    GetPage(
      name: Routes.playbookRead,
      page: () => const PlayBookReadView(),
      binding: PlayBookReadBinding(),
    ),
  ];
}
