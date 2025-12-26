class PaymentProviderIntentDto {
  final String provider;
  final int intentId;
  final String providerIntentId;
  final String initUrl;

  PaymentProviderIntentDto({
    required this.provider,
    required this.intentId,
    required this.providerIntentId,
    required this.initUrl,
  });

  factory PaymentProviderIntentDto.fromJson(Map<String, dynamic> json) {
    return PaymentProviderIntentDto(
      provider: (json['provider'] ?? '').toString(),
      intentId: (json['intent_id'] ?? 0) as int,
      providerIntentId: (json['provider_intent_id'] ?? '').toString(),
      initUrl: (json['init_url'] ?? '').toString(),
    );
  }
}
