// lib/features/vault/presentation/widgets/vault_item_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/vault_item.dart';
import '../../../../core/constants/app_colors.dart';

class VaultItemCard extends StatelessWidget {
  final VaultItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onRestore;

  const VaultItemCard({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.onShare,
    this.onRestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFolder = item.fileType == 'folder';
    final fileExtension = item.name.split('.').last.toLowerCase();

    // Determine icon and color based on file type
    final fileInfo = _getFileInfo(isFolder, fileExtension, item.fileType);

    return Card(
      elevation: 2,
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
                    color: fileInfo.color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(fileInfo.icon, size: 48, color: fileInfo.color),
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 10,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(item.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      if (item.lastOpened != null && !isFolder) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Opened: ${DateFormat('MMM dd').format(item.lastOpened!)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Share button (for non-folders)
            if (!isFolder && onShare != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onShare,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Restore button (if file was moved and has original path)
            if (!isFolder && onRestore != null && item.originalPath != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: GestureDetector(
                  onTap: onRestore,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restore,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Encrypted badge
            if (item.isEncrypted && !isFolder)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 10, color: Colors.white),
                      SizedBox(width: 2),
                      Text(
                        'Encrypted',
                        style: TextStyle(fontSize: 8, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _FileInfo _getFileInfo(bool isFolder, String extension, String fileType) {
    if (isFolder) {
      return _FileInfo(Icons.folder, Colors.blue.shade700);
    }

    // Images
    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
    ].contains(extension)) {
      return _FileInfo(Icons.image, Colors.blue);
    }

    // Videos
    if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'wmv',
      'flv',
      'webm',
    ].contains(extension)) {
      return _FileInfo(Icons.videocam, Colors.red);
    }

    // Audio
    if (['mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg'].contains(extension)) {
      return _FileInfo(Icons.audiotrack, Colors.purple);
    }

    // PDF
    if (extension == 'pdf') {
      return _FileInfo(Icons.picture_as_pdf, Colors.red);
    }

    // Documents
    if (['doc', 'docx'].contains(extension)) {
      return _FileInfo(Icons.description, Colors.blue);
    }

    if (['xls', 'xlsx'].contains(extension)) {
      return _FileInfo(Icons.table_chart, Colors.green);
    }

    if (['ppt', 'pptx'].contains(extension)) {
      return _FileInfo(Icons.slideshow, Colors.orange);
    }

    // Text files
    if (['txt', 'md', 'rtf'].contains(extension)) {
      return _FileInfo(Icons.text_fields, Colors.grey);
    }

    // Default
    return _FileInfo(Icons.insert_drive_file, Colors.grey);
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

class _FileInfo {
  final IconData icon;
  final Color color;

  _FileInfo(this.icon, this.color);
}
