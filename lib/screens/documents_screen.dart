import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/document_model.dart';
import '../theme/theme.dart';
import '../widgets/accent_title.dart';

String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late List<DocumentModel> _documents;
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _documents = List<DocumentModel>.from(DummyDocuments.seed());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _documents;
    return _documents
        .where((d) => d.title.toLowerCase().contains(q))
        .toList();
  }

  void _delete(DocumentModel doc) {
    setState(() {
      _documents = _documents.where((d) => d.id != doc.id).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${doc.title} deleted')),
    );
  }

  Future<void> _confirmDelete(DocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Delete document?',
            style: AppTextStyles.titleMedium,
          ),
          content: Text(
            'Remove “${doc.title}” from your signing history.',
            style: AppTextStyles.secondary.copyWith(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: AppTextStyles.secondary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) _delete(doc);
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filtered;
    final isEmpty = _documents.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _searchOpen
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Search documents',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  setState(() {
                                    _searchOpen = false;
                                    _query = '';
                                    _searchController.clear();
                                  });
                                },
                              ),
                            ),
                          )
                        : AccentTitle(
                            title: 'Documents',
                            accent: AppColors.accentBlue,
                            barWidth: 44,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: 22,
                            ),
                          ),
                  ),
                  if (!_searchOpen)
                    IconButton(
                      onPressed: () => setState(() => _searchOpen = true),
                      icon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: isEmpty
                  ? const _EmptyDocuments()
                  : docs.isEmpty
                      ? Center(
                          child: Text(
                            'No matches',
                            style: AppTextStyles.secondary,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                          itemCount: docs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            return _DocumentHistoryCard(
                              document: doc,
                              onTap: () => context.push(
                                '/documents/detail/${doc.id}',
                                extra: doc,
                              ),
                              onShare: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Share coming soon'),
                                  ),
                                );
                              },
                              onDelete: () => _confirmDelete(doc),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentHistoryCard extends StatelessWidget {
  const _DocumentHistoryCard({
    required this.document,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPdf = document.isPdf;
    final tint = isPdf ? AppColors.accentMintGreen : AppColors.accentPurple;
    final icon = isPdf
        ? Icons.picture_as_pdf_rounded
        : Icons.image_outlined;

    return Dismissible(
      key: ValueKey(document.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      child: Container(
        decoration: AppDecorations.card(
          radius: 19,
          borderColor: tint.withValues(alpha: 0.22),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onDelete,
            borderRadius: BorderRadius.circular(19),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: tint, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.tileLabel,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Signed · ${_shortDate(document.updatedAt)}',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontSize: 11,
                            color: AppColors.accentMintGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onShare,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                color: AppColors.accentMintGreen,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No documents signed yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              'Signed PDFs and images will show up here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
