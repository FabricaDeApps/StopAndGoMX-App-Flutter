class CombineMetric {
  final int id;
  final int organizationId;
  final String key;
  final String name;
  final String? unit;
  final String type;
  final String direction;
  final int decimals;
  final double? min;
  final double? max;
  final bool isActive;

  CombineMetric({
    required this.id,
    required this.organizationId,
    required this.key,
    required this.name,
    required this.unit,
    required this.type,
    required this.direction,
    required this.decimals,
    required this.min,
    required this.max,
    required this.isActive,
  });

  factory CombineMetric.fromJson(Map<String, dynamic> json) {
    return CombineMetric(
      id: (json['id'] ?? 0) as int,
      organizationId: (json['organization_id'] ?? 0) as int,
      key: (json['key'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      unit: json['unit']?.toString(),
      type: (json['type'] ?? 'number') as String,
      direction: (json['direction'] ?? 'lower_is_better') as String,
      decimals: (json['decimals'] ?? 2) as int,
      min: (json['min'] == null) ? null : double.tryParse('${json['min']}'),
      max: (json['max'] == null) ? null : double.tryParse('${json['max']}'),
      isActive: (json['is_active'] ?? true) == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'key': key,
    'name': name,
    'unit': unit,
    'type': type,
    'direction': direction,
    'decimals': decimals,
    'min': min,
    'max': max,
    'is_active': isActive,
  };
}
