// lib/features/vault/presentation/screens/pdf_viewer_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const PdfViewerScreen({
    Key? key,
    required this.filePath,
    required this.fileName,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;
  PDFViewController? _pdfViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
              Get.snackbar('Info', 'Share feature coming soon');
            },
          ),
        ],
        bottom: _totalPages > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.black87,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        onPressed: _currentPage > 1
                            ? () {
                                _pdfViewController?.setPage(_currentPage - 1);
                              }
                            : null,
                      ),
                      Text(
                        'Page $_currentPage of $_totalPages',
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: _currentPage < _totalPages
                            ? () {
                                _pdfViewController?.setPage(_currentPage + 1);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                PDFView(
                  filePath: widget.filePath,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: false,
                  pageFling: true,
                  onError: (error) {
                    print('PDF Error: $error');
                    setState(() {
                      _errorMessage = 'Failed to load PDF: $error';
                      _isLoading = false;
                    });
                  },
                  onRender: (pages) {
                    setState(() {
                      _totalPages = pages ?? 0;
                      _isLoading = false;
                    });
                  },
                  onPageChanged: (page, total) {
                    setState(() {
                      _currentPage = page ?? 0;
                      _totalPages = total ?? 0;
                    });
                  },
                  onViewCreated: (PDFViewController vc) {
                    _pdfViewController = vc;
                  },
                  onPageError: (page, error) {
                    print('Page $page error: $error');
                  },
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
