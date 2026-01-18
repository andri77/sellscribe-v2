import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class CopyButton extends StatefulWidget {
  final String textToCopy;
  final String? label;
  final bool showLabel;
  final double size;
  final Color? color;
  final VoidCallback? onCopied;

  const CopyButton({
    super.key,
    required this.textToCopy,
    this.label,
    this.showLabel = true,
    this.size = 20,
    this.color,
    this.onCopied,
  });

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    
    setState(() => _copied = true);
    
    widget.onCopied?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.label != null 
            ? '${widget.label} copied!' 
            : 'Copied to clipboard'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryColor;
    
    if (widget.showLabel) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _copy,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _copied ? Icons.check : Icons.copy,
                  size: widget.size * 0.8,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  _copied ? 'Copied!' : 'Copy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return IconButton(
      onPressed: _copy,
      icon: Icon(
        _copied ? Icons.check : Icons.copy,
        size: widget.size,
        color: color,
      ),
      tooltip: _copied ? 'Copied!' : 'Copy to clipboard',
    );
  }
}

class CopyAllButton extends StatelessWidget {
  final Map<String, String> contentMap;
  final VoidCallback? onCopied;

  const CopyAllButton({
    super.key,
    required this.contentMap,
    this.onCopied,
  });

  Future<void> _copyAll(BuildContext context) async {
    final buffer = StringBuffer();
    
    contentMap.forEach((key, value) {
      buffer.writeln('=== $key ===');
      buffer.writeln(value);
      buffer.writeln();
    });
    
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All content copied to clipboard'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
    
    onCopied?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _copyAll(context),
      icon: const Icon(Icons.copy_all),
      label: const Text('Copy All'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
