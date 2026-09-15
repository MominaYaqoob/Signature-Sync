enum DocumentStatus { draft, pending, signed, expired }

enum DocumentFileType { pdf, image }

extension DocumentStatusX on DocumentStatus {
  String get statusLabel => switch (this) {
        DocumentStatus.draft => 'Draft',
        DocumentStatus.pending => 'Pending',
        DocumentStatus.signed => 'Signed',
        DocumentStatus.expired => 'Expired',
      };
}

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

  final String id;
  final String title;
  final DocumentStatus status;
  final DateTime updatedAt;
  final int pageCount;
  final String? signerName;
  final DocumentFileType fileType;

  String get statusLabel => status.statusLabel;

  bool get isPdf => fileType == DocumentFileType.pdf;
}

/// Placeholder documents for UI-only screens.
class DummyDocuments {
  DummyDocuments._();

  static List<DocumentModel> seed() => [
        DocumentModel(
          id: 'doc_rent',
          title: 'Rent agreement.pdf',
          status: DocumentStatus.signed,
          updatedAt: DateTime(2026, 9, 10),
          pageCount: 4,
          fileType: DocumentFileType.pdf,
        ),
        DocumentModel(
          id: 'doc_offer',
          title: 'Offer letter.pdf',
          status: DocumentStatus.signed,
          updatedAt: DateTime(2026, 9, 8),
          pageCount: 2,
          fileType: DocumentFileType.pdf,
        ),
        DocumentModel(
          id: 'doc_scan',
          title: 'Signed form.jpg',
          status: DocumentStatus.signed,
          updatedAt: DateTime(2026, 9, 5),
          pageCount: 1,
          fileType: DocumentFileType.image,
        ),
      ];

  static final List<DocumentModel> all = seed();

  static DocumentModel? byId(String id) {
    for (final doc in all) {
      if (doc.id == id) return doc;
    }
    for (final doc in seed()) {
      if (doc.id == id) return doc;
    }
    return null;
  }
}
