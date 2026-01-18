class ProductListing {
  final String? id;
  final String userId;
  final String productName;
  final String category;
  final String? keyFeatures;
  final String? targetAudience;
  final String tone;
  final String? generatedTitle;
  final String? generatedDescription;
  final List<String>? generatedBullets;
  final List<String>? generatedTags;
  final List<String> imageUrls;
  final String platform;
  final DateTime? createdAt;

  ProductListing({
    this.id,
    required this.userId,
    required this.productName,
    required this.category,
    this.keyFeatures,
    this.targetAudience,
    required this.tone,
    this.generatedTitle,
    this.generatedDescription,
    this.generatedBullets,
    this.generatedTags,
    required this.imageUrls,
    this.platform = 'shopify',
    this.createdAt,
  });

  factory ProductListing.fromJson(Map<String, dynamic> json) {
    return ProductListing(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      productName: json['product_name'] as String,
      category: json['category'] as String,
      keyFeatures: json['key_features'] as String?,
      targetAudience: json['target_audience'] as String?,
      tone: json['tone'] as String? ?? 'professional',
      generatedTitle: json['generated_title'] as String?,
      generatedDescription: json['generated_description'] as String?,
      generatedBullets: json['generated_bullets'] != null
          ? List<String>.from(json['generated_bullets'] as List)
          : null,
      generatedTags: json['generated_tags'] != null
          ? List<String>.from(json['generated_tags'] as List)
          : null,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : [],
      platform: json['platform'] as String? ?? 'shopify',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'product_name': productName,
      'category': category,
      'key_features': keyFeatures,
      'target_audience': targetAudience,
      'tone': tone,
      'generated_title': generatedTitle,
      'generated_description': generatedDescription,
      'generated_bullets': generatedBullets,
      'generated_tags': generatedTags,
      'image_urls': imageUrls,
      'platform': platform,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  ProductListing copyWith({
    String? id,
    String? userId,
    String? productName,
    String? category,
    String? keyFeatures,
    String? targetAudience,
    String? tone,
    String? generatedTitle,
    String? generatedDescription,
    List<String>? generatedBullets,
    List<String>? generatedTags,
    List<String>? imageUrls,
    String? platform,
    DateTime? createdAt,
  }) {
    return ProductListing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      keyFeatures: keyFeatures ?? this.keyFeatures,
      targetAudience: targetAudience ?? this.targetAudience,
      tone: tone ?? this.tone,
      generatedTitle: generatedTitle ?? this.generatedTitle,
      generatedDescription: generatedDescription ?? this.generatedDescription,
      generatedBullets: generatedBullets ?? this.generatedBullets,
      generatedTags: generatedTags ?? this.generatedTags,
      imageUrls: imageUrls ?? this.imageUrls,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Categories for product listings
class ProductCategory {
  static const List<String> categories = [
    'Electronics',
    'Clothing & Apparel',
    'Home & Garden',
    'Beauty & Personal Care',
    'Sports & Outdoors',
    'Toys & Games',
    'Food & Beverages',
    'Health & Wellness',
    'Jewelry & Accessories',
    'Books & Media',
    'Automotive',
    'Pet Supplies',
    'Office Supplies',
    'Arts & Crafts',
    'Baby & Kids',
    'Other',
  ];
}

// Tone options for copy generation
class ToneOption {
  static const List<Map<String, String>> tones = [
    {'value': 'professional', 'label': 'Professional', 'description': 'Formal and business-like'},
    {'value': 'casual', 'label': 'Casual', 'description': 'Friendly and conversational'},
    {'value': 'luxury', 'label': 'Luxury', 'description': 'Premium and sophisticated'},
    {'value': 'playful', 'label': 'Playful', 'description': 'Fun and energetic'},
    {'value': 'minimalist', 'label': 'Minimalist', 'description': 'Clean and concise'},
  ];
}
