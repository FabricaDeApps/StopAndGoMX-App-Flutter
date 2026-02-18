import 'package:get/get.dart';

import 'documents_compliance_controller.dart';

class DocumentsComplianceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentsComplianceController>(
      () => DocumentsComplianceController(),
    );
  }
}
