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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Listing History'),
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
            ElevatedButton.icon(
              onPressed: () {
                context.read<ListingProvider>().reset();
                context.go(AppRoutes.upload);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Listing'),
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
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        return _ListingCard(
          listing: listings[index],
          onTap: () => context.go(AppRoutes.results, extra: listings[index].id),
          onDelete: () => _showDeleteDialog(listings[index]),
        );
      },
    );
  }

  Widget _buildListingsList(List<ProductListing> listings) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ListingCard(
          listing: listings[index],
          onTap: () => context.go(AppRoutes.results, extra: listings[index].id),
          onDelete: () => _showDeleteDialog(listings[index]),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ProductListing listing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ListingCard({
    required this.listing,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    listing.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              listing.generatedTitle ?? listing.productName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (listing.generatedDescription != null)
              Text(
                listing.generatedDescription!
                    .replaceAll(RegExp(r'<[^>]*>'), '')
                    .replaceAll('&nbsp;', ' '),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(listing.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                if (listing.imageUrls.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.image_outlined,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${listing.imageUrls.length} images',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM d, yyyy').format(date);
  }
}
