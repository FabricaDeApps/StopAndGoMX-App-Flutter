import 'package:dio/dio.dart';
import '../../config/flavor_config.dart';
import '../../storage/app_storage.dart';

class OrgInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final orgId = FlavorConfig.I.isCustom
        ? FlavorConfig.I.organizationId
        : (AppStorage.getOrganization()?.id ?? FlavorConfig.I.organizationId);
    if (orgId != null) {
      options.headers['X-Organization-Id'] = orgId.toString();
    }
    handler.next(options);
  }
}
