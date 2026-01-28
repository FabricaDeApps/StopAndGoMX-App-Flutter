class NoticeItem {
  final int id;
  final String title;
  final String? message;
  final String? image;
  final String? attachment;
  final DateTime date;

  NoticeItem({
    required this.id,
    required this.title,
    required this.date,
    this.message,
    this.image,
    this.attachment,
  });
}
