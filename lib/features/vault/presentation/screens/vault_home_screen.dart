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

        // Filter button with badge
        Obx(
          () => Stack(
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) => controller.setFilter(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(Icons.grid_view, size: 20),
                        SizedBox(width: 12),
                        Text('All Files'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'images',
                    child: Row(
                      children: [
                        Icon(Icons.image, size: 20, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Images'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'videos',
                    child: Row(
                      children: [
                        Icon(Icons.videocam, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Videos'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'documents',
                    child: Row(
                      children: [
                        Icon(Icons.description, size: 20, color: Colors.green),
                        SizedBox(width: 12),
                        Text('Documents'),
                      ],
                    ),
                  ),
                ],
              ),
              if (controller.selectedFilter.value != 'all')
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // New folder button
        IconButton(
          icon: const Icon(Icons.create_new_folder),
          onPressed: () => _showCreateFolderDialog(controller),
        ),

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
                onPressed: () => _showAddOptions(controller),
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
    return FloatingActionButton(
      onPressed: () => _showAddOptions(controller),
      child: const Icon(Icons.add),
      backgroundColor: AppColors.primary,
    );
  }

  void _showAddOptions(VaultController controller) {
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
              icon: Icons.photo_library,
              title: 'Images',
              subtitle: 'Add photos from gallery',
              color: Colors.blue,
              onTap: () {
                Get.back();
                controller.addImage();
              },
            ),
            const Divider(),
            _buildOptionTile(
              icon: Icons.videocam,
              title: 'Videos',
              subtitle: 'Add videos from gallery',
              color: Colors.red,
              onTap: () {
                Get.back();
                controller.addVideo();
              },
            ),
            const Divider(),
            _buildOptionTile(
              icon: Icons.insert_drive_file,
              title: 'Files',
              subtitle: 'Add documents, PDFs, etc.',
              color: Colors.green,
              onTap: () {
                Get.back();
                controller.addFile();
              },
            ),
            const Divider(),
            _buildOptionTile(
              icon: Icons.note_add,
              title: 'Secure Note',
              subtitle: 'Create an encrypted text note',
              color: Colors.purple,
              onTap: () {
                Get.back();
                _showCreateNoteDialog(controller);
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

  void _showCreateFolderDialog(VaultController controller) {
    final TextEditingController folderNameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create New Folder'),
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

  void _showCreateNoteDialog(VaultController controller) {
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
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: 'Note content',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                controller.createSecureNote(
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
              controller.restoreItem(item);
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
              controller.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
