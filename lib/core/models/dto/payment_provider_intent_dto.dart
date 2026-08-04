class PaymentProviderIntentDto {
  final int paymentId;
  final String provider;
  final String paymentMethod;
  final String amount;
  final String currency;
  final int intentId;
  final String? providerIntentId;
  final String? initUrl;
  final String status;
  final String? statusDetail;
  final String? reference;
  final String? ticketUrl;
  final DateTime? expiresAt;
  final PaymentInstructionsDto? paymentInstructions;
  final bool reused;

  const PaymentProviderIntentDto({
    required this.paymentId,
    required this.provider,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
    required this.intentId,
    required this.providerIntentId,
    required this.initUrl,
    required this.status,
    required this.statusDetail,
    required this.reference,
    required this.ticketUrl,
    required this.expiresAt,
    required this.paymentInstructions,
    required this.reused,
  });

  factory PaymentProviderIntentDto.fromJson(Map<String, dynamic> json) {
    final instructions = _asMap(json['payment_instructions']);

    return PaymentProviderIntentDto(
      paymentId: _asInt(json['payment_id']),
      provider: _asString(json['provider']),
      paymentMethod: _asString(json['payment_method'], fallback: 'card'),
      amount: _asString(json['amount'], fallback: '0.00'),
      currency: _asString(json['currency'], fallback: 'MXN'),
      intentId: _asInt(json['intent_id']),
      providerIntentId: _asNullableString(json['provider_intent_id']),
      initUrl: _asNullableString(json['init_url']),
      status: _asString(json['status'], fallback: 'created'),
      statusDetail: _asNullableString(json['status_detail']),
      reference: _asNullableString(json['reference']),
      ticketUrl: _asNullableString(json['ticket_url']),
      expiresAt: _asDateTime(json['expires_at']),
      paymentInstructions: instructions == null
          ? null
          : PaymentInstructionsDto.fromJson(instructions),
      reused: _asBool(json['reused']),
    );
  }

  String? get instructionsUrl {
    final preferred = paymentInstructions?.instructionsUrl;
    if (preferred != null && preferred.isNotEmpty) return preferred;
    final ticket = paymentInstructions?.ticketUrl ?? ticketUrl;
    if (ticket != null && ticket.isNotEmpty) return ticket;
    if (initUrl != null && initUrl!.isNotEmpty) return initUrl;
    return null;
  }

  String? get speiReference => paymentInstructions?.reference ?? reference;

  DateTime? get effectiveExpiresAt =>
      paymentInstructions?.expiresAt ?? expiresAt;

  bool get isExpired =>
      status == 'expired' ||
      (effectiveExpiresAt?.isBefore(DateTime.now()) ?? false);

  bool get canRegenerate => const {
    'rejected',
    'cancelled',
    'expired',
    'failed',
    'superseded',
  }.contains(status);
}

class PaymentInstructionsDto {
  final String type;
  final String provider;
  final String status;
  final String? statusDetail;
  final String? reference;
  final String? ticketUrl;
  final String? instructionsUrl;
  final String? instructionsUrlContentType;
  final String? qrUrl;
  final String? qrDisplayMode;
  final DateTime? expiresAt;
  final List<String> steps;

  const PaymentInstructionsDto({
    required this.type,
    required this.provider,
    required this.status,
    required this.statusDetail,
    required this.reference,
    required this.ticketUrl,
    required this.instructionsUrl,
    required this.instructionsUrlContentType,
    required this.qrUrl,
    required this.qrDisplayMode,
    required this.expiresAt,
    required this.steps,
  });

  factory PaymentInstructionsDto.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    return PaymentInstructionsDto(
      type: _asString(json['type']),
      provider: _asString(json['provider']),
      status: _asString(json['status'], fallback: 'created'),
      statusDetail: _asNullableString(json['status_detail']),
      reference: _asNullableString(json['reference']),
      ticketUrl: _asNullableString(json['ticket_url']),
      instructionsUrl: _asNullableString(json['instructions_url']),
      instructionsUrlContentType: _asNullableString(
        json['instructions_url_content_type'],
      ),
      qrUrl: _asNullableString(json['qr_url']),
      qrDisplayMode: _asNullableString(json['qr_display_mode']),
      expiresAt: _asDateTime(json['expires_at']),
      steps: rawSteps is List
          ? rawSteps
                .map((item) => item?.toString().trim() ?? '')
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true';
}

String _asString(dynamic value, {String fallback = ''}) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? fallback : parsed;
}

String? _asNullableString(dynamic value) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? null : parsed;
}

DateTime? _asDateTime(dynamic value) {
  final parsed = _asNullableString(value);
  return parsed == null ? null : DateTime.tryParse(parsed);
}
