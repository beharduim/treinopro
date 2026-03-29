import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Loading indicator otimizado para melhor performance
class OptimizedLoadingIndicator extends StatefulWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const OptimizedLoadingIndicator({
    super.key,
    this.color,
    this.size = 20.0,
    this.strokeWidth = 2.0,
  });

  @override
  State<OptimizedLoadingIndicator> createState() => _OptimizedLoadingIndicatorState();
}

class _OptimizedLoadingIndicatorState extends State<OptimizedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: CircularProgressIndicator(
          strokeWidth: widget.strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.color ?? AppColors.primaryOrange,
          ),
        ),
      ),
    );
  }
}

/// Loading overlay otimizado
class OptimizedLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const OptimizedLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          RepaintBoundary(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const OptimizedLoadingIndicator(size: 30),
                        if (message != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            message!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}