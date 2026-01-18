import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';

class ResultsScreen extends StatefulWidget {
  final String? listingId;

  const ResultsScreen({super.key, this.listingId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.listingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ListingProvider>().getListingById(widget.listingId!);
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Generated Listing'),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<ListingProvider>().reset();
              context.go(AppRoutes.upload);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Listing'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ListingProvider>(
        builder: (context, listingProvider, _) {
          final listing = listingProvider.currentListing;

          if (listing == null) {
            return const Center(
              child: LoadingIndicator(message: 'Loading listing...'),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWideScreen ? 32 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(),
                    const SizedBox(height: 32),

                    // Success message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Listing Generated Successfully!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                                Text(
                                  'Copy the content below to your Shopify store.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.successColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Generated Content
                    if (isWideScreen)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildContentCard(
                                  title: 'Product Title',
                                  content: listing.generatedTitle ?? '',
                                  icon: Icons.title,
                                ),
                                const SizedBox(height: 16),
                                _buildContentCard(
                                  title: 'Product Description',
                                  content: listing.generatedDescription ?? '',
                                  icon: Icons.description,
                                  isHtml: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildBulletsCard(listing.generatedBullets ?? []),
                                const SizedBox(height: 16),
                                _buildTagsCard(listing.generatedTags ?? []),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildContentCard(
                            title: 'Product Title',
                            content: listing.generatedTitle ?? '',
                            icon: Icons.title,
                          ),
                          const SizedBox(height: 16),
                          _buildContentCard(
                            title: 'Product Description',
                            content: listing.generatedDescription ?? '',
                            icon: Icons.description,
                            isHtml: true,
                          ),
                          const SizedBox(height: 16),
                          _buildBulletsCard(listing.generatedBullets ?? []),
                          const SizedBox(height: 16),
                          _buildTagsCard(listing.generatedTags ?? []),
                        ],
                      ),

                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppButton(
                          text: 'Back to Dashboard',
                          variant: AppButtonVariant.outline,
                          onPressed: () => context.go(AppRoutes.home),
                        ),
                        const SizedBox(width: 16),
                        AppButton(
                          text: 'Create Another',
                          icon: Icons.add,
                          onPressed: () {
                            context.read<ListingProvider>().reset();
                            context.go(AppRoutes.upload);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildProgressStep(1, 'Upload', true),
        _buildProgressConnector(true),
        _buildProgressStep(2, 'Details', true),
        _buildProgressConnector(true),
        _buildProgressStep(3, 'Results', true),
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
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$number',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
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

  Widget _buildContentCard({
    required String title,
    required String content,
    required IconData icon,
    bool isHtml = false,
  }) {
    // Strip HTML for copying
    final plainText = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _copyToClipboard(
                  isHtml ? content : plainText,
                  title,
                ),
                icon: const Icon(Icons.copy, size: 20),
                color: AppTheme.primaryColor,
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          SelectableText(
            plainText,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletsCard(List<String> bullets) {
    final bulletText = bullets.map((b) => '• $b').join('\n');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.format_list_bulleted, size: 20, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Bullet Points',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _copyToClipboard(bulletText, 'Bullet points'),
                icon: const Icon(Icons.copy, size: 20),
                color: AppTheme.primaryColor,
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          ...bullets.map((bullet) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: AppTheme.primaryColor)),
                Expanded(
                  child: SelectableText(
                    bullet,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTagsCard(List<String> tags) {
    final tagText = tags.join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tag, size: 20, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'SEO Tags',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _copyToClipboard(tagText, 'Tags'),
                icon: const Icon(Icons.copy, size: 20),
                color: AppTheme.primaryColor,
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
