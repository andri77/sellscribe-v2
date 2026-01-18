import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';

class ImagePickerWidget extends StatelessWidget {
  final List<Uint8List> selectedImages;
  final Function(List<Uint8List>, List<String>) onImagesSelected;
  final Function(int) onImageRemoved;

  const ImagePickerWidget({
    super.key,
    required this.selectedImages,
    required this.onImagesSelected,
    required this.onImageRemoved,
  });

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final images = <Uint8List>[];
        final names = <String>[];
        
        for (final file in result.files) {
          if (file.bytes != null &&
              selectedImages.length + images.length < AppConfig.maxImagesPerListing) {
            images.add(file.bytes!);
            names.add(file.name);
          }
        }
        
        if (images.isNotEmpty) {
          onImagesSelected(images, names);
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button
        InkWell(
          onTap: selectedImages.length < AppConfig.maxImagesPerListing
              ? _pickImages
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: selectedImages.length < AppConfig.maxImagesPerListing
                      ? AppTheme.primaryColor
                      : AppTheme.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedImages.length < AppConfig.maxImagesPerListing
                      ? 'Add Images'
                      : 'Maximum images reached',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: selectedImages.length < AppConfig.maxImagesPerListing
                        ? AppTheme.primaryColor
                        : AppTheme.textMuted,
                  ),
                ),
                Text(
                  '${selectedImages.length}/${AppConfig.maxImagesPerListing} images',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Image preview grid
        if (selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onImageRemoved(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
