class ParentsModel {
  final String? fatherName;
  final String? fatherEmail;
  final String? fatherPhone;
  final String? motherName;
  final String? motherEmail;
  final String? motherPhone;

  ParentsModel({
    this.fatherName,
    this.fatherEmail,
    this.fatherPhone,
    this.motherName,
    this.motherEmail,
    this.motherPhone,
  });

  factory ParentsModel.fromJson(Map<String, dynamic> json) {
    return ParentsModel(
      fatherName: json['father_name'] as String?,
      fatherEmail: json['father_email'] as String?,
      fatherPhone: json['father_phone'] as String?,
      motherName: json['mother_name'] as String?,
      motherEmail: json['mother_email'] as String?,
      motherPhone: json['mother_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'father_name': fatherName,
      'father_email': fatherEmail,
      'father_phone': fatherPhone,
      'mother_name': motherName,
      'mother_email': motherEmail,
      'mother_phone': motherPhone,
    };
  }

  ParentsModel copyWith({
    String? fatherName,
    String? fatherEmail,
    String? fatherPhone,
    String? motherName,
    String? motherEmail,
    String? motherPhone,
  }) {
    return ParentsModel(
      fatherName: fatherName ?? this.fatherName,
      fatherEmail: fatherEmail ?? this.fatherEmail,
      fatherPhone: fatherPhone ?? this.fatherPhone,
      motherName: motherName ?? this.motherName,
      motherEmail: motherEmail ?? this.motherEmail,
      motherPhone: motherPhone ?? this.motherPhone,
    );
  }
}
