import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/product_listing.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

enum ListingStatus {
  initial,
  uploading,
  generating,
  success,
  error,
}

class ListingProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  final StorageService _storageService = StorageService();
  
  ListingStatus _status = ListingStatus.initial;
  ProductListing? _currentListing;
  List<ProductListing> _history = [];
  String? _errorMessage;
  List<String> _uploadedImageUrls = [];
  
  // Getters
  ListingStatus get status => _status;
  ProductListing? get currentListing => _currentListing;
  List<ProductListing> get history => _history;
  String? get errorMessage => _errorMessage;
  List<String> get uploadedImageUrls => _uploadedImageUrls;
  
  // Upload images
  Future<List<String>> uploadImages(List<Uint8List> images, List<String> fileNames) async {
    _status = ListingStatus.uploading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _uploadedImageUrls = await _storageService.uploadImages(images, fileNames);
      _status = ListingStatus.initial;
      notifyListeners();
      return _uploadedImageUrls;
    } catch (e) {
      _errorMessage = 'Failed to upload images: $e';
      _status = ListingStatus.error;
      notifyListeners();
      return [];
    }
  }
  
  // Set image URLs (for web when using data URLs or mock)
  void setImageUrls(List<String> urls) {
    _uploadedImageUrls = urls;
    notifyListeners();
  }
  
  // Clear uploaded images
  void clearImages() {
    _uploadedImageUrls = [];
    notifyListeners();
  }
  
  // Generate listing
  Future<ProductListing?> generateListing({
    required String productName,
    required String category,
    String? keyFeatures,
    String? targetAudience,
    required String tone,
  }) async {
    _status = ListingStatus.generating;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Generate AI content
      final aiResponse = await _aiService.generateListing(
        productName: productName,
        category: category,
        keyFeatures: keyFeatures,
        targetAudience: targetAudience,
        tone: tone,
        imageUrls: _uploadedImageUrls,
      );
      
      // Create listing object
      final listing = ProductListing(
        userId: userId,
        productName: productName,
        category: category,
        keyFeatures: keyFeatures,
        targetAudience: targetAudience,
        tone: tone,
        generatedTitle: aiResponse['title'] as String?,
        generatedDescription: aiResponse['description'] as String?,
        generatedBullets: (aiResponse['bullets'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        generatedTags: (aiResponse['tags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        imageUrls: _uploadedImageUrls,
      );
      
      // Save to database
      final savedListing = await _saveListing(listing);
      
      _currentListing = savedListing;
      _status = ListingStatus.success;
      notifyListeners();
      
      return savedListing;
    } catch (e) {
      _errorMessage = 'Failed to generate listing: $e';
      _status = ListingStatus.error;
      notifyListeners();
      return null;
    }
  }
  
  // Save listing to database
  Future<ProductListing> _saveListing(ProductListing listing) async {
    final response = await SupabaseService.client
        .from('listings')
        .insert(listing.toJson())
        .select()
        .single();
    
    return ProductListing.fromJson(response);
  }
  
  // Get listing by ID
  Future<ProductListing?> getListingById(String id) async {
    try {
      final response = await SupabaseService.client
          .from('listings')
          .select()
          .eq('id', id)
          .single();
      
      _currentListing = ProductListing.fromJson(response);
      notifyListeners();
      return _currentListing;
    } catch (e) {
      _errorMessage = 'Failed to load listing';
      notifyListeners();
      return null;
    }
  }
  
  // Load user's listing history
  Future<void> loadHistory() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;
      
      final response = await SupabaseService.client
          .from('listings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      _history = (response as List)
          .map((json) => ProductListing.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }
  
  // Delete listing
  Future<bool> deleteListing(String id) async {
    try {
      await SupabaseService.client
          .from('listings')
          .delete()
          .eq('id', id);

      _history.removeWhere((listing) => listing.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete listing';
      notifyListeners();
      return false;
    }
  }

  // Update listing (manual edits - no credits consumed)
  Future<ProductListing?> updateListing({
    required String id,
    String? generatedTitle,
    String? generatedDescription,
    List<String>? generatedBullets,
    List<String>? generatedTags,
    String? productName,
    String? category,
    String? keyFeatures,
    String? targetAudience,
    String? tone,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (generatedTitle != null) updateData['generated_title'] = generatedTitle;
      if (generatedDescription != null) updateData['generated_description'] = generatedDescription;
      if (generatedBullets != null) updateData['generated_bullets'] = generatedBullets;
      if (generatedTags != null) updateData['generated_tags'] = generatedTags;
      if (productName != null) updateData['product_name'] = productName;
      if (category != null) updateData['category'] = category;
      if (keyFeatures != null) updateData['key_features'] = keyFeatures;
      if (targetAudience != null) updateData['target_audience'] = targetAudience;
      if (tone != null) updateData['tone'] = tone;

      if (updateData.isEmpty) return _currentListing;

      final response = await SupabaseService.client
          .from('listings')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final updatedListing = ProductListing.fromJson(response);
      _currentListing = updatedListing;

      // Update in history list
      final historyIndex = _history.indexWhere((l) => l.id == id);
      if (historyIndex != -1) {
        _history[historyIndex] = updatedListing;
      }

      notifyListeners();
      return updatedListing;
    } catch (e) {
      _errorMessage = 'Failed to update listing: $e';
      notifyListeners();
      return null;
    }
  }

  // Set current listing for editing
  void setCurrentListing(ProductListing listing) {
    _currentListing = listing;
    notifyListeners();
  }
  
  // Reset state
  void reset() {
    _status = ListingStatus.initial;
    _currentListing = null;
    _errorMessage = null;
    _uploadedImageUrls = [];
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
