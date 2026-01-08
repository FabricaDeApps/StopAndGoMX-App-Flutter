import 'package:get/get.dart';
import 'package:stopandgo/core/models/ecommerce/ecommerce_order_list_item_model.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/routes/app_routes.dart';

class EcommerceOrdersController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();
  final orders = <EcommerceOrderListItemModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      final list = await _api.ecommerceOrders();
      orders.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void openOrder(EcommerceOrderListItemModel o) {
    Get.toNamed(Routes.ecommerceOrderDetail, arguments: {'orderId': o.id});
  }
}
