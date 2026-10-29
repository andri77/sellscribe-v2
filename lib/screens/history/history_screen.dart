import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/product_listing.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().loadHistory();
    });
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
        title: const Text('Listing History'),
        actions: [
          Semantics(
            identifier: 'new-listing-button',
            child: TextButton.icon(
              onPressed: () {
                context.read<ListingProvider>().reset();
                context.go(AppRoutes.upload);
              },
              icon: const Icon(Icons.add),
              label: const Text('New Listing'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ListingProvider>(
        builder: (context, listingProvider, _) {
          final listings = listingProvider.history;

          if (listings.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWideScreen ? 32 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${listings.length} Listings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    if (isWideScreen)
                      _buildListingsGrid(listings)
                    else
                      _buildListingsList(listings),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 24),
            const Text(
              'No listings yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your generated listings will appear here',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Semantics(
              identifier: 'create-first-listing-button',
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<ListingProvider>().reset();
                  context.go(AppRoutes.upload);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsGrid(List<ProductListing> listings) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.0,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        return Semantics(
          identifier: 'listing-card',
          child: _ListingCard(
            listing: listings[index],
            onTap: () => context.go(AppRoutes.results, extra: listings[index].id),
            onEdit: () => context.go(AppRoutes.editListing, extra: listings[index].id),
            onDelete: () => _showDeleteDialog(listings[index]),
          ),
        );
      },
    );
  }

  Widget _buildListingsList(List<ProductListing> listings) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Semantics(
          identifier: 'listing-card',
          child: _ListingCard(
            listing: listings[index],
            onTap: () => context.go(AppRoutes.results, extra: listings[index].id),
            onEdit: () => context.go(AppRoutes.editListing, extra: listings[index].id),
            onDelete: () => _showDeleteDialog(listings[index]),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(ProductListing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
          'Are you sure you want to delete "${listing.generatedTitle ?? listing.productName}"?',
        ),
        actions: [
          Semantics(
            identifier: 'cancel-delete-listing-button',
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          Semantics(
            identifier: 'confirm-delete-listing-button',
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<ListingProvider>().deleteListing(listing.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listing deleted'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ProductListing listing;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListingCard({
    required this.listing,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // All cards use dark background
    final cardBg = AppTheme.primaryColor;
    final borderColor = const Color(0xFF2A2A3E);
    final toneBgColor = const Color(0xFF2A2A3E);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content - clickable
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          listing.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: toneBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          listing.tone.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    listing.generatedTitle ?? listing.productName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  if (listing.generatedDescription != null)
                    Text(
                      listing.generatedDescription!
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .replaceAll('&nbsp;', ' '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(listing.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      if (listing.imageUrls.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.image_outlined,
                          size: 13,
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.imageUrls.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF16161E),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  onTap: onTap,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: onEdit,
                  isPrimary: true,
                ),
                const Spacer(),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: onDelete,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Always use gold for primary, white for others
    final color = isDestructive
        ? AppTheme.errorColor
        : isPrimary
            ? AppTheme.secondaryColor
            : Colors.white70;

    final bgColor = isPrimary
        ? AppTheme.secondaryColor.withOpacity(0.15)
        : Colors.transparent;

    return Semantics(
      identifier: 'listing-${label.toLowerCase()}-button',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
