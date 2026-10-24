import 'package:flutter/material.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/core/navigation/shell_navigation.dart';
import 'package:food_app/feaetures/category_kitchens_screen.dart';
import 'package:food_app/feaetures/hotel_details_screen.dart';
import 'package:food_app/modal/hotel_modal.dart';
import 'package:food_app/provider/category_provider.dart';
import 'package:food_app/provider/hotel_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLinkRouter {
  AppLinkRouter._();

  static const _tabRoutes = <String, int>{
    '/search': 1,
    'search': 1,
    '/subscriptions': 2,
    'subscriptions': 2,
    '/subscribe': 2,
    'subscribe': 2,
    '/notifications': 3,
    'notifications': 3,
    '/notification': 3,
    'notification': 3,
    '/account': 4,
    'account': 4,
  };

  static const _namedRoutes = <String>{
    '/cart',
    '/orders',
    '/support',
    '/create-subscription',
  };

  static AppLinkTarget parseRedirectLink(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const AppLinkTarget(type: AppLinkType.unknown);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return AppLinkTarget(type: AppLinkType.external, externalUrl: trimmed);
    }
    // Tolerate admin-entered links missing the scheme, e.g. "www.example.com".
    if (trimmed.startsWith('www.')) {
      return AppLinkTarget(
        type: AppLinkType.external,
        externalUrl: 'https://$trimmed',
      );
    }

    var path = trimmed;
    String? fragment;
    final hashIdx = path.indexOf('#');
    if (hashIdx >= 0) {
      fragment = path.substring(hashIdx + 1);
      path = path.substring(0, hashIdx);
    }
    if (!path.startsWith('/')) path = '/$path';
    if (path.isEmpty || path == '/') path = '/home';

    if (fragment != null && fragment.isNotEmpty) {
      if (fragment.startsWith('category/')) {
        final id = fragment.substring('category/'.length).trim();
        if (id.isNotEmpty) {
          return AppLinkTarget(
            type: AppLinkType.homeCategoryHighlight,
            section: 'categories',
            id: id,
          );
        }
      }
      return AppLinkTarget(
        type: AppLinkType.homeSection,
        section: fragment,
        path: path,
      );
    }

    if (path == '/home') {
      return const AppLinkTarget(type: AppLinkType.homeSection, section: 'categories', path: '/home');
    }

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      final head = segments.first;
      if (head == 'category' && segments.length >= 2) {
        return AppLinkTarget(
          type: AppLinkType.categoryScreen,
          id: segments[1],
          path: path,
        );
      }
      if ((head == 'kitchen' || head == 'hotel') && segments.length >= 2) {
        return AppLinkTarget(
          type: AppLinkType.kitchenScreen,
          id: segments[1],
          path: path,
        );
      }
    }

    final tabPath = path.startsWith('/') ? path : '/$path';
    if (_tabRoutes.containsKey(tabPath) || _tabRoutes.containsKey(tabPath.substring(1))) {
      return AppLinkTarget(type: AppLinkType.tab, path: tabPath);
    }

    if (_namedRoutes.contains(tabPath)) {
      return AppLinkTarget(type: AppLinkType.namedRoute, path: tabPath);
    }

    return AppLinkTarget(type: AppLinkType.unknown, path: path);
  }

  static Future<void> navigate(
    BuildContext context,
    String link, {
    HomeLinkActions? home,
  }) async {
    final target = parseRedirectLink(link);

    switch (target.type) {
      case AppLinkType.external:
        await _openExternalUrl(target.externalUrl ?? '');
        return;

      case AppLinkType.tab:
        final nav = ShellNavigation.maybeOf(context);
        if (nav == null) return;
        final key = target.path ?? '';
        final index = _tabRoutes[key] ?? _tabRoutes[key.replaceFirst('/', '')];
        if (index != null) {
          nav.switchTab(index);
        }
        return;

      case AppLinkType.namedRoute:
        if (target.path != null) {
          await Navigator.pushNamed(context, target.path!);
        }
        return;

      case AppLinkType.categoryScreen:
        final id = target.id;
        if (id == null || id.isEmpty) return;
        final categories = context.read<CategoryProvider>().categories;
        final match = categories.where((c) => c.id == id).toList();
        final name = match.isNotEmpty ? match.first.name : 'Category';
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryKitchensScreen(
              categoryId: id,
              categoryName: name,
            ),
          ),
        );
        return;

      case AppLinkType.kitchenScreen:
        final id = target.id;
        if (id == null || id.isEmpty) return;
        await _openKitchen(context, id);
        return;

      case AppLinkType.homeSection:
        final nav = ShellNavigation.maybeOf(context);
        nav?.switchTab(0);
        if (home != null && target.section != null) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
          if (!context.mounted) return;
          await home.scrollToSection(target.section!);
        }
        return;

      case AppLinkType.homeCategoryHighlight:
        final nav = ShellNavigation.maybeOf(context);
        nav?.switchTab(0);
        if (home != null) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
          if (!context.mounted) return;
          await home.scrollToSection('categories');
          final id = target.id;
          if (id != null && id.isNotEmpty) {
            await home.highlightCategory(id);
          }
        }
        return;

      case AppLinkType.unknown:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link not available')),
          );
        }
        return;
    }
  }

  /// Opens external links in an in-app browser (Custom Tabs on Android,
  /// SFSafariViewController on iOS) so the user stays inside the app.
  /// Falls back to the system browser if the in-app view is unavailable.
  static Future<void> _openExternalUrl(String rawUrl) async {
    final url = Uri.tryParse(rawUrl.trim());
    if (url == null || !(url.scheme == 'http' || url.scheme == 'https')) {
      return;
    }
    try {
      final opened = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
      if (opened) return;
    } catch (_) {
      // Fall through to the external browser below.
    }
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing else we can do with an unlaunchable URL.
    }
  }

  static Future<void> _openKitchen(BuildContext context, String kitchenId) async {
    final hotels = context.read<HotelProvider>().hotels;
    HotelModel? hotel;
    for (final h in hotels) {
      if (h.id == kitchenId) {
        hotel = h;
        break;
      }
    }

    if (hotel == null) {
      try {
        final menu = await AppServices.instance.kitchenRepository.getKitchenMenu(kitchenId);
        final kitchen = menu['kitchen'] as Map<String, dynamic>?;
        if (kitchen != null) {
          final average = kitchen['averageRating'];
          final total = kitchen['totalReviews'];
          hotel = HotelModel(
            id: kitchenId,
            name: kitchen['kitchenName']?.toString() ?? 'Kitchen',
            imageUrl: 'https://picsum.photos/seed/$kitchenId/600/400',
            rating: average is num ? average.toDouble() : 0,
            reviewCount: total is num ? total.round() : 0,
            cuisine: kitchen['address']?.toString() ?? 'Multi cuisine',
            deliveryTime: 30,
            priceForOne: 200,
            distance: 0,
            isVeg: true,
            isOpen: kitchen['status']?.toString() == 'ACTIVE',
          );
        }
      } catch (_) {
        hotel = null;
      }
    }

    if (!context.mounted) return;
    if (hotel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kitchen not available')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HotelDetailScreen(hotel: hotel!)),
    );
  }
}
