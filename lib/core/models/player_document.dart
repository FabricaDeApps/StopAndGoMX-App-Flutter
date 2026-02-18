// lib/core/models/player_document.dart
class PlayerDocument {
  final int id;
  final int? requiredDocumentId;
  final String originalName;
  final String mimeType;
  final int size;
  final DateTime? uploadedAt;
  final String downloadUrl;

  PlayerDocument({
    required this.id,
    this.requiredDocumentId,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.downloadUrl,
    this.uploadedAt,
  });

  factory PlayerDocument.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(String? s) {
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return PlayerDocument(
      id: json['id'] as int,
      requiredDocumentId: json['required_document_id'] as int?,
      originalName: json['original_name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      size: (json['size'] ?? 0) as int,
      uploadedAt: _parseDate(json['uploaded_at']?.toString()),
      downloadUrl: json['download_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'required_document_id': requiredDocumentId,
      'original_name': originalName,
      'mime_type': mimeType,
      'size': size,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'download_url': downloadUrl,
    };
  }
}
