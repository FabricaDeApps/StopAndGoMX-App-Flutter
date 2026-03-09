import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_env.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'gazzetta_detail_controller.dart';

class GazzettaDetailView extends GetView<GazzettaDetailController> {
  const GazzettaDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.isModuleUnavailable.value) {
          return const _StateMessage('Módulo no disponible.');
        }

        final error = controller.error.value;
        if (error != null && error.isNotEmpty) {
          return _StateMessage('No se pudo cargar: $error');
        }

        final html = controller.htmlContent.value;
        if (html == null || html.trim().isEmpty) {
          return const _StateMessage('La gazzetta no trae contenido HTML.');
        }

        return _HtmlWebView(html: _normalizeHtmlUrls(html), baseUrl: _origin());
      }),
    );
  }

  String _origin() {
    final baseApi = Uri.parse(ApiEnv.baseUrl);
    return '${baseApi.scheme}://${baseApi.host}';
  }

  String _normalizeHtmlUrls(String html) {
    final origin = _origin();
    final srcAbs = RegExp(r'src\s*=\s*"/(.*?)"', caseSensitive: false);
    final srcAbs2 = RegExp(r"src\s*=\s*'/(.*?)'", caseSensitive: false);
    final hrefAbs = RegExp(r'href\s*=\s*"/(.*?)"', caseSensitive: false);
    final hrefAbs2 = RegExp(r"href\s*=\s*'/(.*?)'", caseSensitive: false);

    var out = html.replaceAllMapped(srcAbs, (m) => 'src="$origin/${m[1]}"');
    out = out.replaceAllMapped(srcAbs2, (m) => "src='$origin/${m[1]}'");
    out = out.replaceAllMapped(hrefAbs, (m) => 'href="$origin/${m[1]}"');
    out = out.replaceAllMapped(hrefAbs2, (m) => "href='$origin/${m[1]}'");
    return _ensureResponsiveHtml(out);
  }

  String _ensureResponsiveHtml(String html) {
    const style =
        'body{margin:0;padding:12px;max-width:100%;overflow-x:hidden;box-sizing:border-box;}'
        'img,video,iframe,table{max-width:100%!important;height:auto!important;}'
        'table{width:100%!important;display:block;overflow-x:auto;}';
    const viewport =
        '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">';

    var out = html;
    if (!RegExp(
      '<meta[^>]+name=["\\\']viewport["\\\']',
      caseSensitive: false,
    ).hasMatch(out)) {
      out = '$viewport$out';
    }
    if (!RegExp(r'<style\b', caseSensitive: false).hasMatch(out)) {
      out = '<style>$style</style>$out';
    } else {
      out = '<style>$style</style>$out';
    }
    return out;
  }
}

class _HtmlWebView extends StatefulWidget {
  final String html;
  final String baseUrl;

  const _HtmlWebView({required this.html, required this.baseUrl});

  @override
  State<_HtmlWebView> createState() => _HtmlWebViewState();
}

class _HtmlWebViewState extends State<_HtmlWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (_) => setState(() => _loading = false),
        ),
      );
    _loadHtml();
  }

  @override
  void didUpdateWidget(covariant _HtmlWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html || oldWidget.baseUrl != widget.baseUrl) {
      _loadHtml();
    }
  }

  Future<void> _loadHtml() async {
    setState(() => _loading = true);
    await _controller.loadHtmlString(widget.html, baseUrl: widget.baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  final String text;

  const _StateMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
