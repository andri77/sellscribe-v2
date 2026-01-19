import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';

class CreditPackage {
  final int credits;
  final double price;
  final String? badge;

  const CreditPackage({
    required this.credits,
    required this.price,
    this.badge,
  });

  double get pricePerCredit => price / credits;
}

class PurchaseCreditsScreen extends StatefulWidget {
  const PurchaseCreditsScreen({super.key});

  @override
  State<PurchaseCreditsScreen> createState() => _PurchaseCreditsScreenState();
}

class _PurchaseCreditsScreenState extends State<PurchaseCreditsScreen> {
  static const List<CreditPackage> _packages = [
    CreditPackage(credits: 10, price: 4.99),
    CreditPackage(credits: 25, price: 9.99, badge: 'Popular'),
    CreditPackage(credits: 50, price: 17.99, badge: 'Best Value'),
    CreditPackage(credits: 100, price: 29.99),
  ];

  CreditPackage? _selectedPackage;
  bool _isLoading = false;

  Future<void> _purchaseCredits() async {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a package')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Integrate with payment processor
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedPackage!.credits} credits purchased successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error purchasing credits: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Credits'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Current Credits
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Current Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${user?.creditsRemaining ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'credits',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Packages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final package = _packages[index];
                final isSelected = _selectedPackage == package;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPackage = package;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Theme.of(context).dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Credits
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${package.credits} Credits',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (package.badge != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        package.badge!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${package.pricePerCredit.toStringAsFixed(2)} per credit',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        // Price
                        Text(
                          '\$${package.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),

                        // Selection indicator
                        const SizedBox(width: 12),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textMuted,
                              width: 2,
                            ),
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Purchase Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              text: _selectedPackage != null
                  ? 'Purchase for \$${_selectedPackage!.price.toStringAsFixed(2)}'
                  : 'Select a Package',
              onPressed: _selectedPackage != null ? _purchaseCredits : null,
              isLoading: _isLoading,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
