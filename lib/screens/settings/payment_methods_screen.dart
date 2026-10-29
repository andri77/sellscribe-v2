import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/payment_method.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    // TODO: Load payment methods from backend
    // For now, this is a placeholder
  }

  void _showAddCardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddCardSheet(),
    ).then((result) {
      if (result == true) {
        _loadPaymentMethods();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentMethods.isEmpty
              ? _buildEmptyState()
              : _buildCardList(),
      floatingActionButton: Semantics(
        identifier: 'add-card-button',
        child: FloatingActionButton.extended(
          onPressed: _showAddCardSheet,
          icon: const Icon(Icons.add),
          label: const Text('Add Card'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No payment methods',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a card to purchase credits',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final card = _paymentMethods[index];
        return _buildCardTile(card);
      },
    );
  }

  Widget _buildCardTile(PaymentMethod card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildCardIcon(card.cardBrand),
        title: Text(card.displayName),
        subtitle: Text('Expires ${card.expiryDate}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteCard(card);
                } else if (value == 'default') {
                  _setAsDefault(card);
                }
              },
              itemBuilder: (context) => [
                if (!card.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Text('Set as default'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIcon(CardBrand brand) {
    IconData icon;
    Color color;

    switch (brand) {
      case CardBrand.visa:
        icon = Icons.credit_card;
        color = const Color(0xFF1A1F71);
        break;
      case CardBrand.mastercard:
        icon = Icons.credit_card;
        color = const Color(0xFFEB001B);
        break;
      case CardBrand.amex:
        icon = Icons.credit_card;
        color = const Color(0xFF006FCF);
        break;
      case CardBrand.discover:
        icon = Icons.credit_card;
        color = const Color(0xFFFF6000);
        break;
      default:
        icon = Icons.credit_card;
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  Future<void> _deleteCard(PaymentMethod card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete ${card.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Delete card from backend
      setState(() {
        _paymentMethods.removeWhere((c) => c.id == card.id);
      });
    }
  }

  Future<void> _setAsDefault(PaymentMethod card) async {
    // TODO: Set as default in backend
    setState(() {
      for (var c in _paymentMethods) {
        if (c.id == card.id) {
          _paymentMethods[_paymentMethods.indexOf(c)] = c.copyWith(isDefault: true);
        } else {
          _paymentMethods[_paymentMethods.indexOf(c)] = c.copyWith(isDefault: false);
        }
      }
    });
  }
}

class AddCardSheet extends StatefulWidget {
  const AddCardSheet({super.key});

  @override
  State<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  CardBrand _detectedBrand = CardBrand.unknown;
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String value) {
    setState(() {
      _detectedBrand = PaymentMethod.detectCardBrand(value);
    });
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Integrate with Stripe or payment processor
      // For now, just show success message

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card added successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding card: $e')),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Card',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Card Number
              AppTextField(
                label: 'Card Number',
                semanticsLabel: 'card-number-input',
                controller: _cardNumberController,
                hint: '1234 5678 9012 3456',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.credit_card,
                onChanged: _onCardNumberChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Card number is required';
                  }
                  final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
                  if (cleanNumber.length < 13 || cleanNumber.length > 19) {
                    return 'Invalid card number';
                  }
                  return null;
                },
              ),
              if (_detectedBrand != CardBrand.unknown)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _detectedBrand.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Expiry and CVV
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Expiry Date',
                      semanticsLabel: 'card-expiry-input',
                      controller: _expiryController,
                      hint: 'MM/YY',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                          return 'Use MM/YY';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'CVV',
                      semanticsLabel: 'card-cvv-input',
                      controller: _cvvController,
                      hint: '123',
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3 || value.length > 4) {
                          return 'Invalid CVV';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cardholder Name
              AppTextField(
                label: 'Cardholder Name',
                semanticsLabel: 'cardholder-name-input',
                controller: _nameController,
                hint: 'John Doe',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              AppButton(
                text: 'Add Card',
                semanticsLabel: 'save-card-button',
                onPressed: _saveCard,
                isLoading: _isLoading,
                fullWidth: true,
              ),
              const SizedBox(height: 16),

              // Security note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Your card details are securely encrypted',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
