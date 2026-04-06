// lib/features/vault/presentation/widgets/vault_item_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/vault_item.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/media_service.dart';

class VaultItemCard extends StatelessWidget {
  final VaultItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onShare;

  const VaultItemCard({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaService mediaService = MediaService();
    final isFolder = item.fileType == 'folder';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail or Icon
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isFolder
                        ? Colors.blue.shade50
                        : mediaService.getFileColor(item.name).withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isFolder
                          ? Icons.folder
                          : mediaService.getFileIcon(item.name),
                      size: 48,
                      color: isFolder
                          ? Colors.blue.shade700
                          : mediaService.getFileColor(item.name),
                    ),
                  ),
                ),

                // Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (!isFolder) ...[
                        Text(
                          _formatFileSize(item.fileSize),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      Text(
                        DateFormat('MMM dd, yyyy').format(item.createdAt),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Delete button (only for non-folders or show for folders too)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Share button (only for non-folders)
            if (!isFolder && onShare != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onShare,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
