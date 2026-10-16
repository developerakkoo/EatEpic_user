import 'package:flutter/material.dart';

/// Exposes MainShell tab switching to descendant widgets (e.g. banner link router).
class ShellNavigation extends InheritedWidget {
  const ShellNavigation({
    super.key,
    required this.switchTab,
    required super.child,
  });

  final void Function(int index) switchTab;

  static ShellNavigation? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellNavigation>();
  }

  static ShellNavigation of(BuildContext context) {
    final nav = maybeOf(context);
    assert(nav != null, 'ShellNavigation not found in widget tree');
    return nav!;
  }

  @override
  bool updateShouldNotify(ShellNavigation oldWidget) => false;
}

/// Home-specific actions for in-page scroll and category highlight.
class HomeLinkActions {
  const HomeLinkActions({
    required this.scrollToSection,
    required this.highlightCategory,
  });

  final Future<void> Function(String sectionKey) scrollToSection;
  final Future<void> Function(String categoryId) highlightCategory;
}

enum AppLinkType {
  external,
  tab,
  namedRoute,
  categoryScreen,
  kitchenScreen,
  homeSection,
  homeCategoryHighlight,
  unknown,
}

class AppLinkTarget {
  const AppLinkTarget({
    required this.type,
    this.path,
    this.id,
    this.section,
    this.externalUrl,
  });

  final AppLinkType type;
  final String? path;
  final String? id;
  final String? section;
  final String? externalUrl;
}
