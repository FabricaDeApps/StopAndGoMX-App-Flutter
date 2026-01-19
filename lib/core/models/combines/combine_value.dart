class CombineValue {
  final MetricMini? metric;
  final double? valueNumber;
  final String? valueText;
  final Map<String, dynamic>? meta;

  CombineValue({
    required this.metric,
    required this.valueNumber,
    required this.valueText,
    required this.meta,
  });

  factory CombineValue.fromJson(Map<String, dynamic> json) {
    return CombineValue(
      metric: json['metric'] == null
          ? null
          : MetricMini.fromJson(json['metric'] as Map<String, dynamic>),
      valueNumber: json['value_number'] == null
          ? null
          : double.tryParse('${json['value_number']}'),
      valueText: json['value_text']?.toString(),
      meta: json['meta'] is Map<String, dynamic>
          ? (json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'metric': metric?.toJson(),
    'value_number': valueNumber,
    'value_text': valueText,
    'meta': meta,
  };
}

class MetricMini {
  final String key;
  final String? name;
  final String? unit;
  final String? type;
  final String? direction;
  final int? decimals;

  MetricMini({
    required this.key,
    required this.name,
    required this.unit,
    required this.type,
    required this.direction,
    required this.decimals,
  });

  factory MetricMini.fromJson(Map<String, dynamic> json) => MetricMini(
    key: (json['key'] ?? '') as String,
    name: json['name']?.toString(),
    unit: json['unit']?.toString(),
    type: json['type']?.toString(),
    direction: json['direction']?.toString(),
    decimals: json['decimals'] is int
        ? json['decimals'] as int
        : int.tryParse('${json['decimals']}'),
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'unit': unit,
    'type': type,
    'direction': direction,
    'decimals': decimals,
  };
}
