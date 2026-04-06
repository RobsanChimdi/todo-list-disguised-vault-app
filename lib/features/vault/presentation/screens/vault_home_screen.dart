// lib/features/vault/presentation/screens/vault_home_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/vualt_controller.dart';
import '../widgets/vault_item_card.dart';
import 'file_viewer_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class VaultHomeScreen extends StatelessWidget {
  const VaultHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final VaultController controller = Get.find<VaultController>();

    return Scaffold(
      appBar: _buildAppBar(controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = controller.getFilteredItems();

        if (items.isEmpty) {
          return _buildEmptyState(controller);
        }

        return _buildItemGrid(items, controller);
      }),
      floatingActionButton: _buildFloatingActionButton(controller),
    );
  }

  PreferredSizeWidget _buildAppBar(VaultController controller) {
    return AppBar(
      title: Obx(
        () => Text(
          controller.currentFolder.value.isEmpty
              ? 'Secure Vault'
              : 'Folder: ${controller.currentFolder.value}',
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
        return const SizedBox.shrink(); // Return empty widget instead of null
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            _showSearchDialog(controller);
          },
        ),
        Obx(
          () => PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => controller.setFilter(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Files')),
              const PopupMenuItem(value: 'images', child: Text('Images')),
              const PopupMenuItem(value: 'videos', child: Text('Videos')),
              const PopupMenuItem(value: 'documents', child: Text('Documents')),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.create_new_folder),
          onPressed: () => _showCreateFolderDialog(controller),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            _showLogoutDialog(controller);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(VaultController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Vault is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add files to your secure vault',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              CustomButton(
                text: 'Add Files',
                onPressed: () => _showAddOptions(),
                icon: Icons.add,
              ),
              CustomButton(
                text: 'Create Folder',
                onPressed: () => _showCreateFolderDialog(controller),
                icon: Icons.create_new_folder,
                isOutlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List items, VaultController controller) {
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
              final file = await controller.getDecryptedFile(item);
              if (file != null) {
                Get.to(() => FileViewerScreen(file: file, item: item));
              }
            }
          },
          onDelete: () {
            _showDeleteConfirmation(controller, item);
          },
          onShare: () {
            controller.shareItem(item);
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton(VaultController controller) {
    return FloatingActionButton(
      onPressed: () => _showAddOptions(),
      child: const Icon(Icons.add),
      backgroundColor: AppColors.primary,
    );
  }

  void _showAddOptions() {
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
              'Add to Vault',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.photo,
              title: 'Image',
              subtitle: 'Add photos from gallery',
              onTap: () {
                Get.back();
                Get.find<VaultController>().addImage();
              },
            ),
            const Divider(),
            _buildOptionTile(
              icon: Icons.videocam,
              title: 'Video',
              subtitle: 'Add videos from gallery',
              onTap: () {
                Get.back();
                Get.find<VaultController>().addVideo();
              },
            ),
            const Divider(),
            _buildOptionTile(
              icon: Icons.insert_drive_file,
              title: 'File',
              subtitle: 'Add documents, PDFs, etc.',
              onTap: () {
                Get.back();
                Get.find<VaultController>().addFile();
              },
            ),
            const Divider(),
            _buildOptionTile(
              icon: Icons.note_add,
              title: 'Secure Note',
              subtitle: 'Create an encrypted text note',
              onTap: () {
                Get.back();
                _showCreateNoteDialog();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(VaultController controller) {
    final TextEditingController folderNameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: folderNameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter folder name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (folderNameController.text.trim().isNotEmpty) {
                controller.createFolder(folderNameController.text.trim());
              }
              Get.back();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateNoteDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create Secure Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Note title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: 'Note content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Get.find<VaultController>().createSecureNote(
                  titleController.text.trim(),
                  contentController.text,
                );
              }
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 32, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showSearchDialog(VaultController controller) {
    String query = '';
    showDialog(
      context: Get.context!,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Vault'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter file name...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => query = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                controller.setSearchQuery(query);
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(VaultController controller, dynamic item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteItem(item);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
          TextButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text('Exit', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
