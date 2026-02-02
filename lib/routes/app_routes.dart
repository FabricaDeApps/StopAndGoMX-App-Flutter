import 'package:get/get.dart';
import 'package:stopandgo/core/models/player_document.dart';
import 'package:stopandgo/modules/assign_player/index.dart';
import 'package:stopandgo/modules/attendece_game/index.dart';
import 'package:stopandgo/modules/auth/login_binding.dart';
import 'package:stopandgo/modules/auth/login_view.dart';
import 'package:stopandgo/modules/broadcast_live/broadcast_live_view.dart';
import 'package:stopandgo/modules/broadcast_live/index.dart';
import 'package:stopandgo/modules/checkins/checkins_view.dart';
import 'package:stopandgo/modules/checkins/index.dart';
import 'package:stopandgo/modules/combine_create/combine_create_view.dart';
import 'package:stopandgo/modules/combine_create/index.dart';
import 'package:stopandgo/modules/combine_event_detail/combine_event_detail_binding.dart';
import 'package:stopandgo/modules/combine_event_detail/combine_event_detail_view.dart';
import 'package:stopandgo/modules/combine_event_results/combine_event_results_view.dart';
import 'package:stopandgo/modules/combine_event_results/index.dart';
import 'package:stopandgo/modules/combine_events/combine_events_binding.dart';
import 'package:stopandgo/modules/combine_events/combine_events_view.dart';
import 'package:stopandgo/modules/combine_metric_leader_board/combine_metric_leader_board_binding.dart';
import 'package:stopandgo/modules/combine_metric_leader_board/combine_metric_leader_board_view.dart';
import 'package:stopandgo/modules/combine_result_create/combine_result_create_view.dart';
import 'package:stopandgo/modules/combine_result_create/index.dart';
import 'package:stopandgo/modules/complete_game/complete_game_binding.dart';
import 'package:stopandgo/modules/complete_game/complete_game_view.dart';
import 'package:stopandgo/modules/create_metric/create_metric_view.dart';
import 'package:stopandgo/modules/create_metric/index.dart';
import 'package:stopandgo/modules/create_trainning/index.dart';
import 'package:stopandgo/modules/ecommerce_cart/ecommerce_cart_binding.dart';
import 'package:stopandgo/modules/ecommerce_cart/ecommerce_cart_view.dart';
import 'package:stopandgo/modules/ecommerce_checkout/ecommerce_checkout_binding.dart';
import 'package:stopandgo/modules/ecommerce_checkout/ecommerce_checkout_view.dart';
import 'package:stopandgo/modules/ecommerce_home/ecommerce_home_view.dart';
import 'package:stopandgo/modules/ecommerce_home/index.dart';
import 'package:stopandgo/modules/ecommerce_order_detail/ecommerce_order_detail_binding.dart';
import 'package:stopandgo/modules/ecommerce_order_detail/ecommerce_order_detail_view.dart';
import 'package:stopandgo/modules/ecommerce_order_result/ecommerce_order_result_view.dart';
import 'package:stopandgo/modules/ecommerce_order_result/index.dart';
import 'package:stopandgo/modules/ecommerce_orders/ecommerce_orders_view.dart';
import 'package:stopandgo/modules/ecommerce_orders/index.dart';
import 'package:stopandgo/modules/ecommerce_payment/ecommerce_payment_view.dart';
import 'package:stopandgo/modules/ecommerce_payment/index.dart';
import 'package:stopandgo/modules/ecommerce_product_detail/ecommerce_product_detail_view.dart';
import 'package:stopandgo/modules/ecommerce_product_detail/index.dart';
import 'package:stopandgo/modules/ecommerce_products/ecommerce_products_view.dart';
import 'package:stopandgo/modules/ecommerce_products/index.dart';
import 'package:stopandgo/modules/game_detail/game_detail_view.dart';
import 'package:stopandgo/modules/game_detail/index.dart';
import 'package:stopandgo/modules/game_gallery/game_gallery_view.dart';
import 'package:stopandgo/modules/game_gallery/index.dart';
import 'package:stopandgo/modules/home/index.dart';
import 'package:stopandgo/modules/image_view/image_binding.dart';
import 'package:stopandgo/modules/image_view/image_view.dart';
import 'package:stopandgo/modules/init_live/index.dart';
import 'package:stopandgo/modules/init_live/init_live_view.dart';
import 'package:stopandgo/modules/make_payment/index.dart';
import 'package:stopandgo/modules/my_profile/index.dart';
import 'package:stopandgo/modules/my_profile/my_profile_view.dart';
import 'package:stopandgo/modules/new_game/index.dart';
import 'package:stopandgo/modules/no_category/index.dart';
import 'package:stopandgo/modules/no_category/no_category_view.dart';
import 'package:stopandgo/modules/parents_info/index.dart';
import 'package:stopandgo/modules/parents_info/parents_info_view.dart';
import 'package:stopandgo/modules/play_book_go/index.dart';
import 'package:stopandgo/modules/play_book_go/play_book_view.dart';
import 'package:stopandgo/modules/play_book_create/play_book_create_binding.dart';
import 'package:stopandgo/modules/play_book_create/play_book_create_view.dart';
import 'package:stopandgo/modules/play_book_list/index.dart';
import 'package:stopandgo/modules/play_book_list/play_book_list_view.dart';
import 'package:stopandgo/modules/play_book_read/index.dart';
import 'package:stopandgo/modules/play_book_read/play_book_read_view.dart';
import 'package:stopandgo/modules/player_documents/player_documents_binding.dart';
import 'package:stopandgo/modules/player_documents/player_documents_view.dart';
import 'package:stopandgo/modules/player_trainings/player_trainings_binding.dart';
import 'package:stopandgo/modules/player_trainings/player_trainings_view.dart';
import 'package:stopandgo/modules/roster/roster_binding.dart';
import 'package:stopandgo/modules/roster/roster_view.dart';
import 'package:stopandgo/modules/sign_in/sign_in_binding.dart';
import 'package:stopandgo/modules/sign_in/sign_in_view.dart';
import 'package:stopandgo/modules/splash/splash_binding.dart';
import 'package:stopandgo/modules/splash/splash_view.dart';
import 'package:stopandgo/modules/training_attendance/index.dart';
import 'package:stopandgo/modules/training_attendance/training_attendance_view.dart';
import 'package:stopandgo/modules/trainnings/index.dart';
import 'package:stopandgo/modules/watch_live/index.dart';
import 'package:stopandgo/modules/watch_live/watch_live_view.dart';

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
      name: Routes.playbookCreate,
      page: () => const PlayBookCreateView(),
      binding: PlayBookCreateBinding(),
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
    GetPage(
      name: Routes.ecommerceHome,
      page: () => const EcommerceHomeView(),
      binding: EcommerceHomeBinding(),
    ),
    GetPage(
      name: Routes.ecommerceProductList,
      page: () => const EcommerceProductsView(),
      binding: EcommerceProductsBinding(),
    ),
    GetPage(
      name: Routes.ecommerceProductDetail,
      page: () => const EcommerceProductDetailView(),
      binding: EcommerceProductDetailBinding(),
    ),
    GetPage(
      name: Routes.ecommerceCart,
      page: () => const EcommerceCartView(),
      binding: EcommerceCartBinding(),
    ),
    GetPage(
      name: Routes.ecommerceCheckout,
      page: () => const EcommerceCheckoutView(),
      binding: EcommerceCheckoutBinding(),
    ),
    GetPage(
      name: Routes.ecommercePayment,
      page: () => const EcommercePaymentView(),
      binding: EcommercePaymentBinding(),
    ),
    GetPage(
      name: Routes.ecommercePayment,
      page: () => const EcommercePaymentView(),
      binding: EcommercePaymentBinding(),
    ),
    GetPage(
      name: Routes.ecommerceOrderResult,
      page: () => const EcommerceOrderResultView(),
      binding: EcommerceOrderResultBinding(),
    ),
    GetPage(
      name: Routes.ecommerceOrders,
      page: () => const EcommerceOrdersView(),
      binding: EcommerceOrdersBinding(),
    ),
    GetPage(
      name: Routes.ecommerceOrderDetail,
      page: () => const EcommerceOrderDetailView(),
      binding: EcommerceOrderDetailBinding(),
    ),
    GetPage(
      name: Routes.initLive,
      page: () => const InitLiveView(),
      binding: InitLiveBinding(),
    ),
    GetPage(
      name: Routes.broadcastLive,
      page: () => const BroadcastLiveView(),
      binding: BroadcastLiveBinding(),
    ),
    GetPage(
      name: Routes.watchLive,
      page: () => const WatchLiveView(),
      binding: WatchLiveBinding(),
    ),
    GetPage(
      name: Routes.playerTrainnings,
      page: () => const PlayerTrainingsView(),
      binding: PlayerTrainingsBinding(),
    ),
    GetPage(
      name: Routes.combineEvents,
      page: () => const CombineEventsView(),
      binding: CombineEventsBinding(),
    ),
    GetPage(
      name: Routes.combineCreate,
      page: () => const CombineCreateView(),
      binding: CombineCreateBinding(),
    ),
    GetPage(
      name: Routes.combineDetail,
      page: () => const CombineEventDetailView(),
      binding: CombineEventDetailBinding(),
    ),
    GetPage(
      name: Routes.combineResultCreate,
      page: () => const CombineResultCreateView(),
      binding: CombineResultCreateBinding(),
    ),
    GetPage(
      name: Routes.combineMetricLeaderBoard,
      page: () => const CombineMetricLeaderBoardView(),
      binding: CombineMetricLeaderBoardBinding(),
    ),
    GetPage(
      name: Routes.combineEventResults,
      page: () => const CombineEventResultsView(),
      binding: CombineEventResultsBinding(),
    ),
    GetPage(
      name: Routes.combineCreateMetrics,
      page: () => const CreateMetricView(),
      binding: CreateMetricBinding(),
    ),
    GetPage(
      name: Routes.parentsInfo,
      page: () => const ParentsInfoView(),
      binding: ParentsInfoBinding(),
    ),
    GetPage(
      name: Routes.checkins,
      page: () => const CheckinsView(),
      binding: CheckinsBinding(),
    ),
    GetPage(
      name: Routes.gameDetail,
      page: () => const GameDetailView(),
      binding: GameDetailBinding(),
    ),
    GetPage(
      name: Routes.gameGallery,
      page: () => const GameGalleryView(),
      binding: GameGalleryBinding(),
    ),
  ];
}
