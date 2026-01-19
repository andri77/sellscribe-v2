import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/product_listing.dart';
import 'supabase_service.dart';

class AiService {
  static const String _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';
  
  // Generate listing using OpenAI with Vision
  Future<Map<String, dynamic>> generateListing({
    required String productName,
    required String category,
    String? keyFeatures,
    String? targetAudience,
    required String tone,
    List<String>? imageUrls,
  }) async {
    // Use mock if no API key
    if (AppConfig.useMockAi) {
      return _getMockResponse(productName, category, tone);
    }

    final hasImages = imageUrls != null && imageUrls.isNotEmpty;
    final prompt = _buildPrompt(
      productName: productName,
      category: category,
      keyFeatures: keyFeatures,
      targetAudience: targetAudience,
      tone: tone,
      hasImages: hasImages,
    );

    try {
      // Build message content with images if available
      final List<Map<String, dynamic>> userContent = [];

      // Add images first so the AI can analyze them
      if (imageUrls != null && imageUrls.isNotEmpty) {
        for (final imageUrl in imageUrls) {
          userContent.add({
            'type': 'image_url',
            'image_url': {
              'url': imageUrl,
              'detail': 'high', // Use high detail for better product analysis
            },
          });
        }
      }

      // Add the text prompt
      userContent.add({
        'type': 'text',
        'text': prompt,
      });

      final response = await http.post(
        Uri.parse(_openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.openaiApiKey}',
        },
        body: jsonEncode({
          'model': AppConfig.aiModel,
          'messages': [
            {
              'role': 'system',
              'content': _systemPromptWithVision,
            },
            {
              'role': 'user',
              'content': userContent,
            },
          ],
          'max_tokens': AppConfig.maxTokens,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse JSON from response
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!);
        }
        throw Exception('Failed to parse AI response');
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('AI Service error: $e');
      // Fall back to mock on error
      return _getMockResponse(productName, category, tone);
    }
  }
  
  // Alternative: Call Supabase Edge Function
  Future<Map<String, dynamic>> generateListingViaEdgeFunction({
    required String productName,
    required String category,
    String? keyFeatures,
    String? targetAudience,
    required String tone,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'generate-listing',
        body: {
          'productName': productName,
          'category': category,
          'keyFeatures': keyFeatures,
          'targetAudience': targetAudience,
          'tone': tone,
          'imageUrls': imageUrls,
        },
      );
      
      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Edge function error: ${response.status}');
      }
    } catch (e) {
      return _getMockResponse(productName, category, tone);
    }
  }
  
  String _buildPrompt({
    required String productName,
    required String category,
    String? keyFeatures,
    String? targetAudience,
    required String tone,
    bool hasImages = false,
  }) {
    final imageInstruction = hasImages
        ? '\n\nIMPORTANT: Analyze the product images carefully. Describe the actual product you see - its colors, materials, design details, size, and any visible features. Base your description on what you observe in the images.'
        : '';

    return '''
Generate a Shopify product listing for:

Product Name: $productName
Category: $category
Key Features: ${keyFeatures ?? 'Analyze from images if available'}
Target Audience: ${targetAudience ?? 'General consumers'}
Tone: $tone
$imageInstruction
Please provide a complete product listing in JSON format based on what you see in the images and the information provided.
''';
  }

  static const String _systemPrompt = '''
You are an expert Shopify product copywriter. Generate compelling product listings that drive sales.

OUTPUT FORMAT (respond with valid JSON only):
{
  "title": "SEO-optimized title (max 70 characters)",
  "description": "Compelling product description (150-300 words with HTML formatting like <p>, <strong>, <ul><li>)",
  "bullets": ["Benefit 1", "Benefit 2", "Benefit 3", "Benefit 4", "Benefit 5"],
  "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
}

GUIDELINES:
- Title: Include main keyword, be specific and compelling
- Description: Address pain points, highlight benefits, include call-to-action
- Bullets: Start with action verbs, focus on benefits over features
- Tags: Include category, material, style, and trending search terms

Respond ONLY with the JSON object, no additional text.
''';

  static const String _systemPromptWithVision = '''
You are an expert Shopify product copywriter with keen visual analysis skills. When product images are provided, carefully analyze them to identify:

1. PRODUCT DETAILS: Color, material, texture, size, shape
2. DESIGN ELEMENTS: Patterns, logos, stitching, hardware, embellishments
3. QUALITY INDICATORS: Craftsmanship, finish, construction
4. USE CONTEXT: How the product might be used or worn
5. UNIQUE FEATURES: What makes this product stand out

Use these visual observations to write accurate, specific, and compelling product descriptions.

OUTPUT FORMAT (respond with valid JSON only):
{
  "title": "SEO-optimized title based on actual product (max 70 characters)",
  "description": "Detailed product description based on visual analysis (150-300 words with HTML formatting like <p>, <strong>, <ul><li>). Describe actual colors, materials, and features you observe.",
  "bullets": ["Specific benefit/feature 1", "Specific benefit/feature 2", "Specific benefit/feature 3", "Specific benefit/feature 4", "Specific benefit/feature 5"],
  "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
}

GUIDELINES:
- Title: Be specific about what you see (e.g., "Navy Blue Leather Crossbody Bag" not just "Bag")
- Description: Mention actual colors, materials, dimensions if visible, and specific design details
- Bullets: Describe real features you observe, not generic benefits
- Tags: Include specific colors, materials, styles, and product attributes you identify

Respond ONLY with the JSON object, no additional text.
''';
  
  // Mock response for development/demo
  Map<String, dynamic> _getMockResponse(String productName, String category, String tone) {
    final toneAdjective = tone == 'luxury' ? 'Premium' : 
                          tone == 'casual' ? 'Awesome' :
                          tone == 'playful' ? 'Amazing' : 'Professional';
    
    return {
      'title': '$toneAdjective $productName - $category Essentials',
      'description': '''
<p>Introducing the <strong>$productName</strong> - your perfect $category companion designed to exceed expectations.</p>

<p>Whether you're looking for quality, durability, or style, this product delivers on all fronts. Crafted with attention to detail and built to last, it's the smart choice for discerning customers.</p>

<p><strong>Why Choose This Product?</strong></p>
<ul>
  <li>Premium quality materials for lasting durability</li>
  <li>Thoughtfully designed for maximum functionality</li>
  <li>Perfect for everyday use or special occasions</li>
</ul>

<p>Don't settle for less. Upgrade your $category collection today and experience the difference quality makes.</p>
''',
      'bullets': [
        'Premium quality craftsmanship ensures long-lasting durability',
        'Versatile design perfect for any occasion',
        'Easy to use and maintain for everyday convenience',
        'Satisfaction guaranteed with our quality promise',
        'Fast shipping and excellent customer support',
      ],
      'tags': [
        category.toLowerCase().replaceAll(' ', '-'),
        productName.toLowerCase().split(' ').first,
        'bestseller',
        'premium-quality',
        'fast-shipping',
      ],
    };
  }
}
