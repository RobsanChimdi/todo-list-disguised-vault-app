// lib/features/vault/presentation/screens/vault_home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_first_app/features/vault/domain/entities/vault_item.dart';
import '../controllers/vault_controller.dart';
import '../widgets/vault_item_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../routes/app_routes.dart';

class VaultHomeScreen extends StatelessWidget {
  const VaultHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final VaultController controller = Get.find<VaultController>();

    return Scaffold(
      appBar: _buildAppBar(controller),
      body: _buildBody(controller),
      floatingActionButton: _buildFloatingActionButton(controller),
    );
  }

  PreferredSizeWidget _buildAppBar(VaultController controller) {
    return AppBar(
      title: Obx(
        () => Text(
          controller.currentFolder.value.isEmpty
              ? 'Secure Vault'
              : '📁 ${controller.currentFolder.value}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: Obx(() {
        if (controller.currentFolder.value.isNotEmpty) {
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => controller.goToRoot(),
          );
        }
        return const SizedBox.shrink();
      }),
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(controller),
        ),

        // Add custom folder button (only in root)
        Obx(() {
          if (controller.currentFolder.value.isEmpty) {
            return IconButton(
              icon: const Icon(Icons.create_new_folder),
              onPressed: () => _showCreateCustomFolderDialog(controller),
            );
          }
          return const SizedBox.shrink();
        }),

        // Logout button
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _showLogoutDialog(controller),
        ),
      ],
    );
  }

  Widget _buildBody(VaultController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.items.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = controller.getFilteredItems();

      if (items.isEmpty) {
        return _buildEmptyState(controller);
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshItems(),
        child: _buildItemGrid(items, controller),
      );
    });
  }

  Widget _buildEmptyState(VaultController controller) {
    // Show predefined folders if in root and no folders exist
    if (controller.currentFolder.value.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No folders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create a custom folder',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Create Custom Folder',
              onPressed: () => _showCreateCustomFolderDialog(controller),
              icon: Icons.create_new_folder,
            ),
          ],
        ),
      );
    }

    // Empty state inside a folder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Folder is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add items to this folder',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List<VaultItem> items, VaultController controller) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return VaultItemCard(
          item: item,
          onTap: () async {
            if (item.fileType == 'folder') {
              controller.navigateToFolder(item.name);
            } else {
              // Show loading
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              try {
                final file = await controller.getDecryptedFile(item);
                if (file != null && context.mounted) {
                  Get.back(); // Close loading
                  Get.toNamed(
                    AppRoutes.fileViewer,
                    arguments: {'path': file.path, 'item': item},
                  );
                } else {
                  Get.back(); // Close loading
                  Get.snackbar('Error', 'Failed to open file');
                }
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar('Error', 'Failed to open file: $e');
              }
            }
          },
          onDelete: () {
            _showDeleteConfirmation(controller, item);
          },
          onShare: () {
            controller.shareItem(item);
          },
          onRestore: item.originalPath != null
              ? () {
                  _showRestoreConfirmation(controller, item);
                }
              : null,
        );
      },
    );
  }

  Widget _buildFloatingActionButton(VaultController controller) {
    return Obx(() {
      // Show add button only when inside a folder
      if (controller.currentFolder.value.isNotEmpty) {
        return FloatingActionButton(
          onPressed: () => _showAddOptionsForFolder(
            controller,
            controller.currentFolder.value,
          ),
          child: const Icon(Icons.add),
          backgroundColor: AppColors.primary,
        );
      }
      return const SizedBox.shrink();
    });
  }

  void _showAddOptionsForFolder(VaultController controller, String folderName) {
    Widget content;

    // Show different options based on folder type
    switch (folderName) {
      case 'Images':
        content = _buildImageFolderOptions(controller, folderName);
        break;
      case 'Videos':
        content = _buildVideoFolderOptions(controller, folderName);
        break;
      case 'Documents':
        content = _buildDocumentFolderOptions(controller, folderName);
        break;
      case 'Audio':
        content = _buildAudioFolderOptions(controller, folderName);
        break;
      default:
        // Custom folder - allow adding any file type
        content = _buildCustomFolderOptions(controller, folderName);
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: content,
      ),
    );
  }

  Widget _buildImageFolderOptions(
    VaultController controller,
    String folderName,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Add to Images',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildOptionTile(
          icon: Icons.photo_library,
          title: 'Upload from Gallery',
          subtitle: 'Select images from your gallery',
          color: Colors.blue,
          onTap: () {
            Get.back();
            controller.addImageToFolder(folderName);
          },
        ),
        const Divider(),
        _buildOptionTile(
          icon: Icons.camera_alt,
          title: 'Capture with Camera',
          subtitle: 'Take a new photo',
          color: Colors.orange,
          onTap: () {
            Get.back();
            controller.captureImageToFolder(folderName);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVideoFolderOptions(
    VaultController controller,
    String folderName,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Add to Videos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildOptionTile(
          icon: Icons.video_library,
          title: 'Upload Video',
          subtitle: 'Select video from gallery',
          color: Colors.red,
          onTap: () {
            Get.back();
            controller.addVideoToFolder(folderName);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDocumentFolderOptions(
    VaultController controller,
    String folderName,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Add to Documents',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildOptionTile(
          icon: Icons.insert_drive_file,
          title: 'Upload Document',
          subtitle: 'PDF, DOC, TXT, etc.',
          color: Colors.green,
          onTap: () {
            Get.back();
            controller.addDocumentToFolder(folderName);
          },
        ),
        const Divider(),
        _buildOptionTile(
          icon: Icons.note_add,
          title: 'Create Note',
          subtitle: 'Add a text note',
          color: Colors.purple,
          onTap: () {
            Get.back();
            controller.addNoteToFolder(folderName);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAudioFolderOptions(
    VaultController controller,
    String folderName,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Add to Audio',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildOptionTile(
          icon: Icons.audio_file,
          title: 'Upload Audio',
          subtitle: 'MP3, WAV, AAC, etc.',
          color: Colors.teal,
          onTap: () {
            Get.back();
            controller.addAudioToFolder(folderName);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCustomFolderOptions(
    VaultController controller,
    String folderName,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Add to Folder',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildOptionTile(
          icon: Icons.image,
          title: 'Add Image',
          subtitle: 'Upload or capture image',
          color: Colors.blue,
          onTap: () {
            Get.back();
            _showImageOptions(controller, folderName);
          },
        ),
        const Divider(),
        _buildOptionTile(
          icon: Icons.videocam,
          title: 'Add Video',
          subtitle: 'Upload video',
          color: Colors.red,
          onTap: () {
            Get.back();
            controller.addVideoToFolder(folderName);
          },
        ),
        const Divider(),
        _buildOptionTile(
          icon: Icons.audiotrack,
          title: 'Add Audio',
          subtitle: 'Upload audio file',
          color: Colors.teal,
          onTap: () {
            Get.back();
            controller.addAudioToFolder(folderName);
          },
        ),
        const Divider(),
        _buildOptionTile(
          icon: Icons.insert_drive_file,
          title: 'Add Document',
          subtitle: 'PDF, DOC, TXT, etc.',
          color: Colors.green,
          onTap: () {
            Get.back();
            controller.addDocumentToFolder(folderName);
          },
        ),
        const Divider(),
        _buildOptionTile(
          icon: Icons.note_add,
          title: 'Add Note',
          subtitle: 'Create a text note',
          color: Colors.purple,
          onTap: () {
            Get.back();
            controller.addNoteToFolder(folderName);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showImageOptions(VaultController controller, String folderName) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Image',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.photo_library,
              title: 'Upload from Gallery',
              subtitle: 'Select from gallery',
              color: Colors.blue,
              onTap: () {
                Get.back();
                controller.addImageToFolder(folderName);
              },
            ),
            const Divider(),
            _buildOptionTile(
              icon: Icons.camera_alt,
              title: 'Capture with Camera',
              subtitle: 'Take a new photo',
              color: Colors.orange,
              onTap: () {
                Get.back();
                controller.captureImageToFolder(folderName);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 28, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showCreateCustomFolderDialog(VaultController controller) {
    final TextEditingController folderNameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create Custom Folder'),
        content: TextField(
          controller: folderNameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter folder name',
            prefixIcon: Icon(Icons.folder),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (folderNameController.text.trim().isNotEmpty) {
                controller.createCustomFolder(folderNameController.text.trim());
              }
              Get.back();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(VaultController controller) {
    final TextEditingController searchController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Search Vault'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter file name...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            controller.setSearchQuery(value);
            Get.back();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.setSearchQuery('');
              Get.back();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.setSearchQuery(searchController.text);
              Get.back();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(VaultController controller, VaultItem item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete File'),
        content: Text(
          'Are you sure you want to delete "${item.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteItem(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRestoreConfirmation(VaultController controller, VaultItem item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Restore File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore "${item.name}" to its original location?'),
            const SizedBox(height: 8),
            Text(
              'Original path: ${item.originalPath}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Add restore functionality
              Get.snackbar('Info', 'Restore functionality coming soon');
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(VaultController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Exit Vault'),
        content: const Text('Are you sure you want to exit the secure vault?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Stay')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Clear any sensitive data and redirect to todo home screen
              controller.logoutAndGoToTodo();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
