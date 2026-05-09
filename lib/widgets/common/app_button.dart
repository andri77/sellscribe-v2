import 'package:flutter/material.dart';
import '../../config/theme.dart';

enum AppButtonVariant { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final double? width;
  final double height;
  final String? semanticsLabel;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.width,
    this.height = 48,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;
    
    switch (variant) {
      case AppButtonVariant.primary:
        button = _buildPrimaryButton();
        break;
      case AppButtonVariant.secondary:
        button = _buildSecondaryButton();
        break;
      case AppButtonVariant.outline:
        button = _buildOutlineButton();
        break;
      case AppButtonVariant.text:
        button = _buildTextButton();
        break;
    }
    
    Widget sized = (fullWidth || width != null)
        ? SizedBox(width: fullWidth ? double.infinity : width, height: height, child: button)
        : SizedBox(height: height, child: button);

    if (semanticsLabel != null) {
      return Semantics(label: semanticsLabel, child: sized);
    }
    return sized;
  }

  Widget _buildPrimaryButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null && !isLoading 
            ? AppTheme.primaryGradient 
            : null,
        color: onPressed == null || isLoading 
            ? Colors.grey[300] 
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildContent(Colors.white),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
        foregroundColor: AppTheme.secondaryColor,
        elevation: 0,
      ),
      child: _buildContent(AppTheme.secondaryColor),
    );
  }

  Widget _buildOutlineButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildContent(AppTheme.primaryColor),
    );
  }

  Widget _buildTextButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildContent(AppTheme.primaryColor),
    );
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    
    return Text(text);
  }
}
