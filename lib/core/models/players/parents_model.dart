class ParentsModel {
  final String? fatherName;
  final String? fatherEmail;
  final String? motherName;
  final String? motherEmail;

  ParentsModel({
    this.fatherName,
    this.fatherEmail,
    this.motherName,
    this.motherEmail,
  });

  factory ParentsModel.fromJson(Map<String, dynamic> json) {
    return ParentsModel(
      fatherName: json['father_name'] as String?,
      fatherEmail: json['father_email'] as String?,
      motherName: json['mother_name'] as String?,
      motherEmail: json['mother_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'father_name': fatherName,
      'father_email': fatherEmail,
      'mother_name': motherName,
      'mother_email': motherEmail,
    };
  }

  ParentsModel copyWith({
    String? fatherName,
    String? fatherEmail,
    String? motherName,
    String? motherEmail,
  }) {
    return ParentsModel(
      fatherName: fatherName ?? this.fatherName,
      fatherEmail: fatherEmail ?? this.fatherEmail,
      motherName: motherName ?? this.motherName,
      motherEmail: motherEmail ?? this.motherEmail,
    );
  }
}
