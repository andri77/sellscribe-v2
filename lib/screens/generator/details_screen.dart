import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/product_listing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_indicator.dart';

class DetailsScreen extends StatefulWidget {
  final List<String> imageUrls;

  const DetailsScreen({super.key, required this.imageUrls});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _keyFeaturesController = TextEditingController();
  final _targetAudienceController = TextEditingController();
  
  String _selectedCategory = ProductCategory.categories.first;
  String _selectedTone = 'professional';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Set image URLs in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().setImageUrls(widget.imageUrls);
    });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _keyFeaturesController.dispose();
    _targetAudienceController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    // Check credits
    final authProvider = context.read<AuthProvider>();
    if (authProvider.creditsRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No credits remaining. Please purchase more credits.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final listingProvider = context.read<ListingProvider>();
      
      // Deduct credit
      final creditDeducted = await authProvider.deductCredits(1);
      if (!creditDeducted) {
        throw Exception('Failed to deduct credits');
      }

      // Generate listing
      final listing = await listingProvider.generateListing(
        productName: _productNameController.text.trim(),
        category: _selectedCategory,
        keyFeatures: _keyFeaturesController.text.trim(),
        targetAudience: _targetAudienceController.text.trim(),
        tone: _selectedTone,
      );

      if (mounted && listing != null) {
        context.go(AppRoutes.results, extra: listing.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating listing: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    if (_isGenerating) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GeneratingAnimation(),
                const SizedBox(height: 48),
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      _buildGeneratingStep('Analyzing product details', true, true),
                      _buildGeneratingStep('Crafting compelling title', true, false),
                      _buildGeneratingStep('Writing product description', false, false),
                      _buildGeneratingStep('Generating bullet points', false, false),
                      _buildGeneratingStep('Creating SEO tags', false, false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.upload),
        ),
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWideScreen ? 32 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  _buildProgressIndicator(),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Tell us about your product',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The more details you provide, the better your listing will be.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  // Product Name
                  AppTextField(
                    label: 'Product Name *',
                    hint: 'e.g., Bamboo Wireless Charging Pad',
                    controller: _productNameController,
                    prefixIcon: Icons.inventory_2_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Category
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textMuted),
                        ),
                        items: ProductCategory.categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Key Features
                  AppTextField(
                    label: 'Key Features',
                    hint: 'e.g., Eco-friendly materials, Fast charging, LED indicator, Non-slip base',
                    controller: _keyFeaturesController,
                    prefixIcon: Icons.list_alt_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Target Audience
                  AppTextField(
                    label: 'Target Audience (Optional)',
                    hint: 'e.g., Tech enthusiasts, Eco-conscious consumers, Office workers',
                    controller: _targetAudienceController,
                    prefixIcon: Icons.people_outline,
                  ),
                  const SizedBox(height: 20),

                  // Tone Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Copy Tone',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ToneOption.tones.map((tone) {
                          final isSelected = _selectedTone == tone['value'];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTone = tone['value']!;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tone['label']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tone['description']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? AppTheme.primaryColor.withOpacity(0.8)
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Credit info
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This will use 1 credit. You have ${auth.creditsRemaining} credits remaining.',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppButton(
                        text: 'Back',
                        variant: AppButtonVariant.outline,
                        onPressed: () => context.go(AppRoutes.upload),
                      ),
                      AppButton(
                        text: 'Generate Listing',
                        icon: Icons.auto_awesome,
                        onPressed: _handleGenerate,
                      ),
                    ],
                  ),
                ],
              ),
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
        _buildProgressConnector(true),
        _buildProgressStep(2, 'Details', true),
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

  Widget _buildGeneratingStep(String text, bool isCompleted, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20)
          else if (isActive)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.circle_outlined, color: Colors.grey[300], size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isCompleted || isActive
                  ? AppTheme.textPrimary
                  : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
