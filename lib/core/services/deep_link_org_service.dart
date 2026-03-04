import 'dart:io';

import 'package:flutter/services.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class DeepLinkOrgService {
  static const _channel = MethodChannel('app.stopandgo/deeplink');

  static Future<void> bootstrap() async {
    if (FlavorConfig.I.isCustom || !FlavorConfig.I.isMain) return;

    final orgIdFromLink = await _readOrgIdFromInitialDeepLink();
    if (orgIdFromLink != null) {
      await _applyPendingOrganization(orgIdFromLink);
      return;
    }

    if (!Platform.isAndroid) return;
    final orgIdFromReferrer = await _readOrgIdFromInstallReferrer();
    if (orgIdFromReferrer != null) {
      await _applyPendingOrganization(orgIdFromReferrer);
    }
  }

  static Future<void> _applyPendingOrganization(int orgId) async {
    FlavorConfig.I.updateOrganizationId(orgId);
    await AppStorage.setPendingOrganizationId(orgId);
  }

  static Future<int?> _readOrgIdFromInitialDeepLink() async {
    try {
      final raw = await _channel.invokeMethod<String>('getInitialDeepLink');
      return _extractOrgIdFromRaw(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<int?> _readOrgIdFromInstallReferrer() async {
    try {
      final data = await _channel.invokeMethod<dynamic>('getInstallReferrer');
      if (data is! Map) return null;

      final raw = data['installReferrer']?.toString();
      return _extractOrgIdFromRaw(raw);
    } catch (_) {
      return null;
    }
  }

  static int? _extractOrgIdFromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();

    // Caso URL completa: stopandgo://open?org_id=123
    final asUri = Uri.tryParse(value);
    if (asUri != null && asUri.queryParameters.isNotEmpty) {
      final orgIdFromUrl = _parseOrgIdFromMap(asUri.queryParameters);
      if (orgIdFromUrl != null) return orgIdFromUrl;
    }

    // Caso referrer plano: org_id=123&utm_source=...
    try {
      final fromReferrer = Uri.splitQueryString(value);
      return _parseOrgIdFromMap(fromReferrer);
    } catch (_) {
      return null;
    }
  }

  static int? _parseOrgIdFromMap(Map<String, String> map) {
    final candidates = [
      map['org_id'],
      map['organization_id'],
      map['orgId'],
      map['organizationId'],
    ];

    for (final candidate in candidates) {
      final parsed = int.tryParse((candidate ?? '').trim());
      if (parsed != null && parsed > 0) return parsed;
    }

    // Permite referrers que envían un deep-link anidado como query param.
    final nestedCandidates = [
      map['link'],
      map['deep_link'],
      map['deeplink'],
      map['redirect'],
      map['af_dp'],
    ];
    for (final nested in nestedCandidates) {
      if (nested == null || nested.trim().isEmpty) continue;
      final nestedUri = Uri.tryParse(nested.trim());
      if (nestedUri == null || nestedUri.queryParameters.isEmpty) continue;
      final parsedNested = _parseOrgIdFromMap(nestedUri.queryParameters);
      if (parsedNested != null) return parsedNested;
    }

    return null;
  }
}
