import 'package:stopandgo/core/models/gazzetta/gazetta_item.dart';
import 'package:stopandgo/core/models/gazzetta/gazetta_payload.dart';

class GazettaDetail {
  final GazettaItem item;
  final GazettaPayload jsonPayload;
  final String? html;

  const GazettaDetail({
    required this.item,
    required this.jsonPayload,
    this.html,
  });

  int get id => item.id;
  int? get organizationId => item.organizationId;
  DateTime? get weekStart => item.weekStart;
  DateTime? get weekEnd => item.weekEnd;
  String? get status => item.status;
  String? get roleMode => item.roleMode;
  String? get subject => item.subject;
  DateTime? get publishedAt => item.publishedAt;
  DateTime? get sentAt => item.sentAt;
  DateTime? get updatedAt => item.updatedAt;

  factory GazettaDetail.fromJson(Map<String, dynamic> json) {
    return GazettaDetail(
      item: GazettaItem.fromJson(json),
      jsonPayload: GazettaPayload.fromJson(json['json_payload']),
      html: _asString(json['html']) ?? _asString(json['html_version']),
    );
  }

  Map<String, dynamic> toJson() => {
    ...item.toJson(),
    'json_payload': jsonPayload.toJson(),
    'html': html,
  };

  @Deprecated('Use html')
  String? get htmlVersion => html;
}

String? _asString(dynamic value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
