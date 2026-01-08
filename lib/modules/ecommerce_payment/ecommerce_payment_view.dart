import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EcommercePaymentView extends StatelessWidget {
  const EcommercePaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final url = args['url'] as String;
    final orderId = (args['orderId'] as int?) ?? 0;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago seguro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Get.offNamed(
              Routes.ecommerceOrderResult,
              arguments: {'orderId': orderId},
            );
          },
        ),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
