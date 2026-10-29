import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/common/app_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load recent listings
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
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Playfair Display',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'SellScribe',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // Credits display
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A3E)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 6),
                    Semantics(
                      identifier: 'credits-count',
                      child: Text(
                        '${auth.creditsRemaining}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'credits',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'profile-menu',
            icon: const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onSelected: (value) async {
              if (value == 'settings') {
                context.push(AppRoutes.settings);
              } else if (value == 'logout') {
                await context.read<AuthProvider>().signOut();
                if (mounted) {
                  context.go(AppRoutes.login);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.fullName ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          auth.userProfile?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'settings',
                child: Semantics(
                  identifier: 'settings-menu-item',
                  child: const Row(
                    children: [
                      Icon(Icons.settings, size: 18, color: AppTheme.textSecondary),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Semantics(
                  identifier: 'sign-out-menu-item',
                  child: const Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: AppTheme.errorColor),
                      SizedBox(width: 8),
                      Text('Sign out', style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWideScreen ? 32 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                _buildWelcomeSection(context),
                const SizedBox(height: 32),
                
                // Quick actions
                _buildQuickActions(context, isWideScreen),
                const SizedBox(height: 32),
                
                // Recent listings
                _buildRecentListings(context, isWideScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = auth.userProfile?.displayName ?? 'there';
        return Text(
          'Welcome back, $name.',
          style: Theme.of(context).textTheme.displaySmall,
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _ActionCard(
              icon: Icons.edit_note,
              title: 'Create Listing',
              description: 'Generate compelling product copy with AI assistance',
              semanticsLabel: 'create-listing-button',
              isPrimary: true,
              onTap: () {
                context.read<ListingProvider>().reset();
                context.go(AppRoutes.upload);
              },
            ),
            _ActionCard(
              icon: Icons.folder_outlined,
              title: 'View History',
              description: 'Browse and manage your past generations',
              semanticsLabel: 'view-history-button',
              onTap: () => context.go(AppRoutes.history),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentListings(BuildContext context, bool isWideScreen) {
    return Consumer<ListingProvider>(
      builder: (context, listingProvider, _) {
        final recentListings = listingProvider.history.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Listings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (recentListings.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.history),
                    icon: const Text('View all'),
                    label: Icon(Icons.arrow_forward, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (recentListings.isEmpty)
              _buildEmptyState(context)
            else
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: recentListings.map((listing) {
                  return _ListingCard(
                    title: listing.generatedTitle ?? listing.productName,
                    category: listing.category,
                    createdAt: listing.createdAt,
                    listingId: listing.id,
                    onTap: () {
                      context.go(AppRoutes.results, extra: listing.id);
                    },
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // All cards use dark background
    final cardBg = AppTheme.primaryColor;
    final borderColor = const Color(0xFF2A2A3E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.edit_note,
              size: 36,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No listings yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first AI-powered product listing',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          AppButton(
            text: 'Create Your First Listing',
            semanticsLabel: 'create-first-listing-button',
            icon: Icons.add,
            onPressed: () {
              context.read<ListingProvider>().reset();
              context.go(AppRoutes.upload);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isPrimary;
  final VoidCallback onTap;
  final String? semanticsLabel;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.isPrimary = false,
    required this.onTap,
    this.semanticsLabel,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // All cards use dark background
    final cardBg = AppTheme.primaryColor;
    final borderColor = const Color(0xFF2A2A3E);

    return Semantics(
      label: widget.semanticsLabel,
      identifier: widget.semanticsLabel,
      button: widget.semanticsLabel != null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isHovered ? AppTheme.secondaryColor.withOpacity(0.5) : borderColor),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppTheme.secondaryColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          transform: _isHovered
              ? (Matrix4.identity()..translate(0.0, -4.0))
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  color: AppTheme.secondaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    widget.isPrimary ? 'Get started' : 'View all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppTheme.secondaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ListingCard extends StatefulWidget {
  final String title;
  final String category;
  final DateTime? createdAt;
  final String? listingId;
  final VoidCallback onTap;

  const _ListingCard({
    required this.title,
    required this.category,
    this.createdAt,
    this.listingId,
    required this.onTap,
  });

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // All cards use dark background
    final cardBg = AppTheme.primaryColor;
    final borderColor = const Color(0xFF2A2A3E);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? AppTheme.secondaryColor.withOpacity(0.5) : borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppTheme.secondaryColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 4 : 1),
              ),
            ],
          ),
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
                      widget.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.listingId != null)
                    IconButton(
                      onPressed: () => context.go(AppRoutes.editListing, extra: widget.listingId),
                      icon: Icon(Icons.edit_outlined, size: 18),
                      color: AppTheme.secondaryColor,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Edit listing',
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.createdAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 13,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(widget.createdAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
