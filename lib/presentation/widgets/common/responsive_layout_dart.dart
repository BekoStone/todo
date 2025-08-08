// File: lib/presentation/widgets/common/responsive_layout.dart

import 'package:flutter/material.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import '../../../core/utils/responsive_utils.dart';

/// A responsive layout widget that adapts its child based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? fallback;
  final EdgeInsets? padding;
  final bool maintainAspectRatio;
  final double? aspectRatio;

  const ResponsiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
    this.padding,
    this.maintainAspectRatio = false,
    this.aspectRatio, required Scaffold child,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final breakpoint = ResponsiveUtils.getBreakpoint(context);
    
    Widget child;
    
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        child = mobile ?? tablet ?? desktop ?? fallback ?? _buildDefaultContent();
        break;
      case ResponsiveBreakpoint.tablet:
        child = tablet ?? desktop ?? mobile ?? fallback ?? _buildDefaultContent();
        break;
      case ResponsiveBreakpoint.desktop:
        child = desktop ?? tablet ?? mobile ?? fallback ?? _buildDefaultContent();
        break;
    }

    // Apply aspect ratio if specified
    if (maintainAspectRatio && aspectRatio != null) {
      child = AspectRatio(
        aspectRatio: aspectRatio!,
        child: child,
      );
    }

    // Apply padding if specified
    if (padding != null) {
      child = Padding(
        padding: padding!,
        child: child,
      );
    }

    return child;
  }

  Widget _buildDefaultContent() {
    return const Center(
      child: Text(
        'No content provided for this screen size',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

/// A responsive builder that provides screen information
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    ResponsiveBreakpoint breakpoint,
    Size screenSize,
    Orientation orientation,
  ) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final breakpoint = ResponsiveUtils.getBreakpoint(context);
    
    return builder(
      context,
      breakpoint,
      mediaQuery.size,
      mediaQuery.orientation,
    );
  }
}

/// A widget that conditionally shows content based on screen size
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = ResponsiveUtils.getBreakpoint(context);
    
    bool isVisible;
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        isVisible = visibleOnMobile;
        break;
      case ResponsiveBreakpoint.tablet:
        isVisible = visibleOnTablet;
        break;
      case ResponsiveBreakpoint.desktop:
        isVisible = visibleOnDesktop;
        break;
    }

    if (isVisible) {
      return child;
    } else {
      return replacement ?? const SizedBox.shrink();
    }
  }
}

/// A responsive container that adjusts its properties based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget? child;
  final double? mobileMaxWidth;
  final double? tabletMaxWidth;
  final double? desktopMaxWidth;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final EdgeInsets? mobileMargin;
  final EdgeInsets? tabletMargin;
  final EdgeInsets? desktopMargin;
  final AlignmentGeometry? alignment;
  final Decoration? decoration;

  const ResponsiveContainer({
    super.key,
    this.child,
    this.mobileMaxWidth,
    this.tabletMaxWidth,
    this.desktopMaxWidth,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileMargin,
    this.tabletMargin,
    this.desktopMargin,
    this.alignment,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = ResponsiveUtils.getBreakpoint(context);
    
    double? maxWidth;
    EdgeInsets? padding;
    EdgeInsets? margin;
    
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        maxWidth = mobileMaxWidth;
        padding = mobilePadding;
        margin = mobileMargin;
        break;
      case ResponsiveBreakpoint.tablet:
        maxWidth = tabletMaxWidth ?? mobileMaxWidth;
        padding = tabletPadding ?? mobilePadding;
        margin = tabletMargin ?? mobileMargin;
        break;
      case ResponsiveBreakpoint.desktop:
        maxWidth = desktopMaxWidth ?? tabletMaxWidth ?? mobileMaxWidth;
        padding = desktopPadding ?? tabletPadding ?? mobilePadding;
        margin = desktopMargin ?? tabletMargin ?? mobileMargin;
        break;
    }

    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: padding,
      margin: margin,
      alignment: alignment,
      decoration: decoration,
      child: child,
    );
  }
}

/// A responsive grid that adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double? childAspectRatio;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns,
    this.desktopColumns,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = ResponsiveUtils.getBreakpoint(context);
    
    int columns;
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        columns = mobileColumns;
        break;
      case ResponsiveBreakpoint.tablet:
        columns = tabletColumns ?? (mobileColumns * 2);
        break;
      case ResponsiveBreakpoint.desktop:
        columns = desktopColumns ?? tabletColumns ?? (mobileColumns * 3);
        break;
    }

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio ?? 1.0,
      physics: physics,
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }
}

/// A responsive wrap that adjusts spacing based on screen size
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final WrapAlignment alignment;
  final double? mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;
  final double? mobileRunSpacing;
  final double? tabletRunSpacing;
  final double? desktopRunSpacing;
  final Axis direction;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.alignment = WrapAlignment.start,
    this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
    this.mobileRunSpacing,
    this.tabletRunSpacing,
    this.desktopRunSpacing,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = ResponsiveUtils.getBreakpoint(context);
    
    double spacing = 8.0;
    double runSpacing = 8.0;
    
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        spacing = mobileSpacing ?? 8.0;
        runSpacing = mobileRunSpacing ?? 8.0;
        break;
      case ResponsiveBreakpoint.tablet:
        spacing = tabletSpacing ?? mobileSpacing ?? 12.0;
        runSpacing = tabletRunSpacing ?? mobileRunSpacing ?? 12.0;
        break;
      case ResponsiveBreakpoint.desktop:
        spacing = desktopSpacing ?? tabletSpacing ?? mobileSpacing ?? 16.0;
        runSpacing = desktopRunSpacing ?? tabletRunSpacing ?? mobileRunSpacing ?? 16.0;
        break;
    }

    return Wrap(
      direction: direction,
      alignment: alignment,
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}

/// A responsive text widget that adjusts size based on screen
class ResponsiveText extends StatelessWidget {
  final String text;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = ResponsiveUtils.getBreakpoint(context);
    
    double fontSize;
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        fontSize = mobileFontSize ?? 14.0;
        break;
      case ResponsiveBreakpoint.tablet:
        fontSize = tabletFontSize ?? mobileFontSize ?? 16.0;
        break;
      case ResponsiveBreakpoint.desktop:
        fontSize = desktopFontSize ?? tabletFontSize ?? mobileFontSize ?? 18.0;
        break;
    }

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// A responsive column that adjusts spacing based on screen size
class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;

  const ResponsiveColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = ResponsiveUtils.getBreakpoint(context);
    
    double spacing;
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        spacing = mobileSpacing ?? 8.0;
        break;
      case ResponsiveBreakpoint.tablet:
        spacing = tabletSpacing ?? mobileSpacing ?? 12.0;
        break;
      case ResponsiveBreakpoint.desktop:
        spacing = desktopSpacing ?? tabletSpacing ?? mobileSpacing ?? 16.0;
        break;
    }

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(height: spacing));
      }
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: spacedChildren,
    );
  }
}

/// A responsive row that adjusts spacing based on screen size
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = ResponsiveUtils.getBreakpoint(context);
    
    double spacing;
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        spacing = mobileSpacing ?? 8.0;
        break;
      case ResponsiveBreakpoint.tablet:
        spacing = tabletSpacing ?? mobileSpacing ?? 12.0;
        break;
      case ResponsiveBreakpoint.desktop:
        spacing = desktopSpacing ?? tabletSpacing ?? mobileSpacing ?? 16.0;
        break;
    }

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(width: spacing));
      }
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: spacedChildren,
    );
  }
}

/// Extension on BuildContext for responsive utilities
extension ResponsiveContextExtension on BuildContext {
  /// Get the current responsive breakpoint
  ResponsiveBreakpoint get breakpoint => ResponsiveUtils.getBreakpoint(this);
  
  /// Check if current screen is mobile
  bool get isMobile => breakpoint == ResponsiveBreakpoint.mobile;
  
  /// Check if current screen is tablet
  bool get isTablet => breakpoint == ResponsiveBreakpoint.tablet;
  
  /// Check if current screen is desktop
  bool get isDesktop => breakpoint == ResponsiveBreakpoint.desktop;
  
  /// Get responsive value based on current breakpoint
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        return mobile;
      case ResponsiveBreakpoint.tablet:
        return tablet ?? mobile;
      case ResponsiveBreakpoint.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}