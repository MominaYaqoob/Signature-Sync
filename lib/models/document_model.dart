import 'package:hive/hive.dart';

part 'document_model.g.dart';

@HiveType(typeId: 3)
enum DocumentStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  pending,
  @HiveField(2)
  signed,
  @HiveField(3)
  expired,
}

@HiveType(typeId: 4)
enum DocumentFileType {
  @HiveField(0)
  pdf,
  @HiveField(1)
  image,
}

extension DocumentStatusX on DocumentStatus {
  String get statusLabel => switch (this) {
        DocumentStatus.draft => 'Draft',
        DocumentStatus.pending => 'Pending',
        DocumentStatus.signed => 'Signed',
        DocumentStatus.expired => 'Expired',
      };
}

@HiveType(typeId: 1)
class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
    this.pageCount = 1,
    this.signerName,
    this.fileType = DocumentFileType.pdf,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DocumentStatus status;

  @HiveField(3)
  final DateTime updatedAt;

  @HiveField(4)
  final int pageCount;

  @HiveField(5)
  final String? signerName;

  @HiveField(6)
  final DocumentFileType fileType;

  String get statusLabel => status.statusLabel;

  bool get isPdf => fileType == DocumentFileType.pdf;
}
