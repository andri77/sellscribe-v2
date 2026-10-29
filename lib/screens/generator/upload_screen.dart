import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/common/app_button.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final List<Uint8List> _selectedImages = [];
  final List<String> _fileNames = [];
  bool _isUploading = false;

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.bytes != null &&
                _selectedImages.length < AppConfig.maxImagesPerListing) {
              _selectedImages.add(file.bytes!);
              _fileNames.add(file.name);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _fileNames.removeAt(index);
    });
  }

  Future<void> _handleContinue() async {
    if (_selectedImages.isEmpty) {
      // Allow proceeding without images
      context.go(AppRoutes.details, extra: <String>[]);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final listingProvider = context.read<ListingProvider>();
      final urls = await listingProvider.uploadImages(_selectedImages, _fileNames);

      if (mounted) {
        if (urls.isNotEmpty) {
          context.go(AppRoutes.details, extra: urls);
        } else {
          // If upload failed, still proceed with empty URLs (demo mode)
          context.go(AppRoutes.details, extra: <String>[]);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Upload Product Images'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWideScreen ? 32 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Add Product Photos',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload up to 5 images of your product. This helps our AI understand your product better.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // Upload area
                _buildUploadArea(),
                const SizedBox(height: 24),

                // Selected images
                if (_selectedImages.isNotEmpty) ...[
                  Text(
                    'Selected Images (${_selectedImages.length}/${AppConfig.maxImagesPerListing})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImageGrid(),
                  const SizedBox(height: 24),
                ],

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label: 'skip-upload-button',
                      identifier: 'skip-upload-button',
                      child: TextButton(
                        onPressed: _selectedImages.isEmpty
                            ? () => context.go(AppRoutes.details, extra: <String>[])
                            : null,
                        child: const Text('Skip this step'),
                      ),
                    ),
                    AppButton(
                      text: 'Continue',
                      semanticsLabel: 'continue-button',
                      icon: Icons.arrow_forward,
                      onPressed: _handleContinue,
                      isLoading: _isUploading,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildProgressStep(1, 'Upload', true),
        _buildProgressConnector(false),
        _buildProgressStep(2, 'Details', false),
        _buildProgressConnector(false),
        _buildProgressStep(3, 'Results', false),
      ],
    );
  }

  Widget _buildProgressStep(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppTheme.primaryColor : AppTheme.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isCompleted ? AppTheme.primaryColor : Colors.grey[200],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Semantics(
      label: 'upload-images-button',
      identifier: 'upload-images-button',
      button: true,
      child: InkWell(
        onTap: _selectedImages.length < AppConfig.maxImagesPerListing
            ? _pickImages
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Click to upload images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'PNG, JPG, WEBP up to 10MB each',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _selectedImages.asMap().entries.map((entry) {
        final index = entry.key;
        final bytes = entry.value;

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => _removeImage(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
