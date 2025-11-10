class GenericResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  GenericResponse({required this.success, required this.message, this.data});

  factory GenericResponse.fromJson(Map<String, dynamic> json) {
    return GenericResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      // algunas APIs devuelven el objeto en "game" u otro wrapper:
      data: (json['data'] is Map)
          ? Map<String, dynamic>.from(json['data'])
          : (json['game'] is Map)
          ? Map<String, dynamic>.from(json['game'])
          : null,
    );
  }
}
