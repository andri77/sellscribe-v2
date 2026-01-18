import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class StorageService {
  static const String _bucketName = 'product-images';
  final _uuid = const Uuid();
  
  // Upload image and return public URL
  Future<String> uploadImage(Uint8List imageBytes, String fileName) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    // Generate unique file name
    final extension = fileName.split('.').last;
    final uniqueName = '${userId}/${_uuid.v4()}.$extension';
    
    // Upload to Supabase Storage
    await SupabaseService.storage
        .from(_bucketName)
        .uploadBinary(uniqueName, imageBytes);
    
    // Get public URL
    final publicUrl = SupabaseService.storage
        .from(_bucketName)
        .getPublicUrl(uniqueName);
    
    return publicUrl;
  }
  
  // Upload multiple images
  Future<List<String>> uploadImages(List<Uint8List> images, List<String> fileNames) async {
    final urls = <String>[];
    
    for (var i = 0; i < images.length; i++) {
      final url = await uploadImage(images[i], fileNames[i]);
      urls.add(url);
    }
    
    return urls;
  }
  
  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    // Extract path from URL
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    final bucketIndex = pathSegments.indexOf(_bucketName);
    
    if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
      final path = pathSegments.sublist(bucketIndex + 1).join('/');
      await SupabaseService.storage.from(_bucketName).remove([path]);
    }
  }
  
  // Delete multiple images
  Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }
}
