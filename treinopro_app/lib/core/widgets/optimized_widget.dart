import 'package:flutter/material.dart';

/// Widget wrapper que adiciona otimizações automáticas
class OptimizedWidget extends StatelessWidget {
  final Widget child;
  final bool addRepaintBoundary;
  final bool addAutomaticKeepAlive;
  final String? debugLabel;

  const OptimizedWidget({
    super.key,
    required this.child,
    this.addRepaintBoundary = true,
    this.addAutomaticKeepAlive = false,
    this.debugLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = child;

    // Adiciona RepaintBoundary para otimizar repaint
    if (addRepaintBoundary) {
      result = RepaintBoundary(
        child: result,
      );
    }

    // Adiciona AutomaticKeepAlive se necessário
    if (addAutomaticKeepAlive) {
      result = AutomaticKeepAlive(
        child: result,
      );
    }

    return result;
  }
}

/// Widget otimizado para listas
class OptimizedListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const OptimizedListItem({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Container otimizado com RepaintBoundary automático
class OptimizedContainer extends StatelessWidget {
  final Widget? child;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Decoration? decoration;
  final Decoration? foregroundDecoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Clip clipBehavior;

  const OptimizedContainer({
    super.key,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.child,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        alignment: alignment,
        padding: padding,
        color: color,
        decoration: decoration,
        foregroundDecoration: foregroundDecoration,
        width: width,
        height: height,
        constraints: constraints,
        margin: margin,
        transform: transform,
        transformAlignment: transformAlignment,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}