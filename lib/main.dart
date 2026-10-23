import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/feaetures/language_screen.dart';
import 'package:food_app/feaetures/location_picker_screen.dart';
import 'package:food_app/feaetures/login_screen.dart';
import 'package:food_app/feaetures/main_shell.dart';
import 'package:food_app/feaetures/cart_screen.dart';
import 'package:food_app/feaetures/create_subscription_screen.dart';
import 'package:food_app/feaetures/onboarding_screen.dart';
import 'package:food_app/feaetures/permissions_screen.dart';
import 'package:food_app/feaetures/splash_screen.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/category_provider.dart';
import 'package:food_app/provider/cart_provider.dart';
import 'package:food_app/provider/hotel_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:food_app/provider/catalog_provider.dart';
import 'package:food_app/data/repositories/subscription_repository.dart';
import 'package:food_app/feaetures/orders_list_screen.dart';
import 'package:food_app/provider/order_tracking_provider.dart';
import 'package:food_app/provider/subscription_provider.dart';
import 'package:food_app/provider/theme_provider.dart';
import 'package:food_app/feaetures/support/support_tickets_screen.dart';
import 'package:food_app/provider/notification_provider.dart';
import 'package:food_app/provider/support_provider.dart';
import 'package:provider/provider.dart';

/// Supported app locales.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('hi'),
  Locale('mr'),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  runApp(
    EasyLocalization(
      supportedLocales: kSupportedLocales,
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MyApp(themeProvider: themeProvider),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) {
          final p = LocationProvider();
          p.loadLocation();
          return p;
        }),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => HotelProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        Provider<SubscriptionRepository>(
          create: (_) => AppServices.instance.subscriptionRepository,
        ),
        ChangeNotifierProvider(
          create: (ctx) => SubscriptionProvider(
            ctx.read<SubscriptionRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => OrderTrackingProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'EatEpic',
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            darkTheme: AppTheme.darkTheme,
            theme: AppTheme.lightTheme,
            themeMode: theme.themeMode,
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              final colors = context.colors;
              final isDark = brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  statusBarBrightness:
                      isDark ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor: colors.background,
                  systemNavigationBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/language': (context) => const LanguageScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/permissions': (context) => const PermissionsScreen(),
              '/login': (context) => const LoginScreen(),
              '/location-picker': (context) {
                final args =
                    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                final fromHome = args?['fromHome'] == true;
                return LocationPickerScreen(fromHome: fromHome);
              },
              '/home': (context) => const MainShell(),
              '/cart': (context) => const CartScreen(),
              '/orders': (context) => const OrdersListScreen(),
              '/support': (context) => const SupportTicketsScreen(),
              '/create-subscription': (context) {
                final raw = ModalRoute.of(context)?.settings.arguments;
                String? kid;
                String? mid;
                if (raw is Map) {
                  kid = raw['kitchenId']?.toString();
                  mid = raw['menuItemId']?.toString();
                }
                return CreateSubscriptionScreen(
                  initialKitchenId: kid,
                  initialMenuItemId: mid,
                );
              },
            },
          );
        },
      ),
    );
  }
}
