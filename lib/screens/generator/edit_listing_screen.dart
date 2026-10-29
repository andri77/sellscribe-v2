import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/product_listing.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_indicator.dart';

class EditListingScreen extends StatefulWidget {
  final String listingId;

  const EditListingScreen({super.key, required this.listingId});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bulletsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _productNameController = TextEditingController();
  final _keyFeaturesController = TextEditingController();
  final _targetAudienceController = TextEditingController();

  String _selectedCategory = ProductCategory.categories.first;
  String _selectedTone = 'professional';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  ProductListing? _originalListing;

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  Future<void> _loadListing() async {
    final listing = await context.read<ListingProvider>().getListingById(widget.listingId);
    if (listing != null && mounted) {
      setState(() {
        _originalListing = listing;
        _titleController.text = listing.generatedTitle ?? '';
        _descriptionController.text = _stripHtml(listing.generatedDescription ?? '');
        _bulletsController.text = (listing.generatedBullets ?? []).join('\n');
        _tagsController.text = (listing.generatedTags ?? []).join(', ');
        _productNameController.text = listing.productName;
        _keyFeaturesController.text = listing.keyFeatures ?? '';
        _targetAudienceController.text = listing.targetAudience ?? '';
        _selectedCategory = listing.category;
        _selectedTone = listing.tone;
        _isLoading = false;
      });

      // Add listeners for change detection
      _titleController.addListener(_onFieldChanged);
      _descriptionController.addListener(_onFieldChanged);
      _bulletsController.addListener(_onFieldChanged);
      _tagsController.addListener(_onFieldChanged);
    }
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bulletsController.dispose();
    _tagsController.dispose();
    _productNameController.dispose();
    _keyFeaturesController.dispose();
    _targetAudienceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Parse bullets (split by newline)
      final bullets = _bulletsController.text
          .split('\n')
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty)
          .toList();

      // Parse tags (split by comma)
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final updatedListing = await context.read<ListingProvider>().updateListing(
        id: widget.listingId,
        generatedTitle: _titleController.text.trim(),
        generatedDescription: _descriptionController.text.trim(),
        generatedBullets: bullets,
        generatedTags: tags,
        productName: _productNameController.text.trim(),
        category: _selectedCategory,
        keyFeatures: _keyFeaturesController.text.trim(),
        targetAudience: _targetAudienceController.text.trim(),
        tone: _selectedTone,
      );

      if (mounted && updatedListing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Changes saved successfully'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.history),
          ),
          title: const Text('Edit Listing'),
        ),
        body: const Center(
          child: LoadingIndicator(message: 'Loading listing...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_hasChanges) {
              _showDiscardDialog();
            } else {
              context.go(AppRoutes.history);
            }
          },
        ),
        title: const Text('Edit Listing'),
        actions: [
          if (_hasChanges)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 14, color: AppTheme.warningColor),
                  const SizedBox(width: 4),
                  Text(
                    'Unsaved',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWideScreen ? 32 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: isWideScreen
                  ? _buildWideLayout()
                  : _buildNarrowLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Generated content
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Generated Content', Icons.auto_awesome),
              const SizedBox(height: 16),
              _buildEditableCard(
                title: 'Product Title',
                icon: Icons.title,
                controller: _titleController,
                maxLines: 2,
                onCopy: () => _copyToClipboard(_titleController.text, 'Title'),
              ),
              const SizedBox(height: 16),
              _buildEditableCard(
                title: 'Product Description',
                icon: Icons.description,
                controller: _descriptionController,
                maxLines: 8,
                onCopy: () => _copyToClipboard(_descriptionController.text, 'Description'),
              ),
              const SizedBox(height: 16),
              _buildEditableCard(
                title: 'Bullet Points',
                icon: Icons.format_list_bulleted,
                controller: _bulletsController,
                maxLines: 6,
                hint: 'One bullet point per line',
                onCopy: () => _copyToClipboard(_bulletsController.text, 'Bullets'),
              ),
              const SizedBox(height: 16),
              _buildEditableCard(
                title: 'SEO Tags',
                icon: Icons.tag,
                controller: _tagsController,
                maxLines: 2,
                hint: 'Comma-separated tags',
                onCopy: () => _copyToClipboard(_tagsController.text, 'Tags'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right column - Product details
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Product Details', Icons.inventory_2_outlined),
              const SizedBox(height: 16),
              _buildProductDetailsCard(),
              const SizedBox(height: 24),
              _buildActionsCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Generated Content', Icons.auto_awesome),
        const SizedBox(height: 16),
        _buildEditableCard(
          title: 'Product Title',
          icon: Icons.title,
          controller: _titleController,
          maxLines: 2,
          onCopy: () => _copyToClipboard(_titleController.text, 'Title'),
        ),
        const SizedBox(height: 16),
        _buildEditableCard(
          title: 'Product Description',
          icon: Icons.description,
          controller: _descriptionController,
          maxLines: 6,
          onCopy: () => _copyToClipboard(_descriptionController.text, 'Description'),
        ),
        const SizedBox(height: 16),
        _buildEditableCard(
          title: 'Bullet Points',
          icon: Icons.format_list_bulleted,
          controller: _bulletsController,
          maxLines: 5,
          hint: 'One bullet point per line',
          onCopy: () => _copyToClipboard(_bulletsController.text, 'Bullets'),
        ),
        const SizedBox(height: 16),
        _buildEditableCard(
          title: 'SEO Tags',
          icon: Icons.tag,
          controller: _tagsController,
          maxLines: 2,
          hint: 'Comma-separated tags',
          onCopy: () => _copyToClipboard(_tagsController.text, 'Tags'),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('Product Details', Icons.inventory_2_outlined),
        const SizedBox(height: 16),
        _buildProductDetailsCard(),
        const SizedBox(height: 24),
        _buildActionsCard(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.secondaryColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildEditableCard({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required int maxLines,
    String? hint,
    required VoidCallback onCopy,
  }) {
    // All cards use dark background
    final cardBg = AppTheme.primaryColor;
    final headerBg = const Color(0xFF16161E);
    final borderColor = const Color(0xFF2A2A3E);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.secondaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 18),
                  color: AppTheme.secondaryColor,
                  tooltip: 'Copy to clipboard',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Editor
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white38),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.white,
              ),
              validator: (value) {
                if (title == 'Product Title' && (value == null || value.isEmpty)) {
                  return 'Title is required';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsCard() {
    // All cards use dark background
    final cardBg = AppTheme.primaryColor;
    final borderColor = const Color(0xFF2A2A3E);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Product Name',
            controller: _productNameController,
            prefixIcon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined, color: AppTheme.secondaryColor),
                  filled: true,
                  fillColor: AppTheme.primaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2),
                  ),
                ),
                dropdownColor: AppTheme.primaryColor,
                iconEnabledColor: AppTheme.secondaryColor,
                style: TextStyle(color: Colors.white),
                items: ProductCategory.categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    _hasChanges = true;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Key Features',
            controller: _keyFeaturesController,
            prefixIcon: Icons.list_alt_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Target Audience',
            controller: _targetAudienceController,
            prefixIcon: Icons.people_outline,
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tone',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ToneOption.tones.map((tone) {
                  final isSelected = _selectedTone == tone['value'];
                  return ChoiceChip(
                    label: Text(tone['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTone = tone['value']!;
                          _hasChanges = true;
                        });
                      }
                    },
                    selectedColor: AppTheme.secondaryColor.withOpacity(0.3),
                    backgroundColor: const Color(0xFF2A2A3E),
                    checkmarkColor: AppTheme.secondaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.secondaryColor : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    // All cards use dark background
    final cardBg = const Color(0xFF16161E);
    final borderColor = const Color(0xFF2A2A3E);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Manual edits are free',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            text: _isSaving ? 'Saving...' : 'Save Changes',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _handleSave,
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'View Listing',
            icon: Icons.visibility_outlined,
            variant: AppButtonVariant.outline,
            onPressed: () => context.go(AppRoutes.results, extra: widget.listingId),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Back to History',
            variant: AppButtonVariant.text,
            onPressed: () {
              if (_hasChanges) {
                _showDiscardDialog();
              } else {
                context.go(AppRoutes.history);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.history);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
