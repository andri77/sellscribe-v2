import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/product_listing.dart';
import 'supabase_service.dart';

class AiService {
  static const String _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';
  
  // Generate listing using OpenAI
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
    
    final prompt = _buildPrompt(
      productName: productName,
      category: category,
      keyFeatures: keyFeatures,
      targetAudience: targetAudience,
      tone: tone,
    );
    
    try {
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
              'content': _systemPrompt,
            },
            {
              'role': 'user',
              'content': prompt,
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
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
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
  }) {
    return '''
Generate a Shopify product listing for:

Product Name: $productName
Category: $category
Key Features: ${keyFeatures ?? 'Not specified'}
Target Audience: ${targetAudience ?? 'General consumers'}
Tone: $tone

Please provide a complete product listing in JSON format.
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
