import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/core/socket/socket_service.dart';
import 'package:food_app/core/storage/catalog_cache.dart';
import 'package:food_app/core/storage/token_storage.dart';
import 'package:food_app/data/repositories/auth_repository.dart';
import 'package:food_app/data/repositories/cart_repository.dart';
import 'package:food_app/data/repositories/catalog_repository.dart';
import 'package:food_app/data/repositories/kitchen_repository.dart';
import 'package:food_app/data/repositories/notification_repository.dart';
import 'package:food_app/data/repositories/order_repository.dart';
import 'package:food_app/data/repositories/subscription_repository.dart';
import 'package:food_app/data/repositories/support_repository.dart';
import 'package:food_app/data/repositories/user_repository.dart';

class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  final tokenStorage = TokenStorage();
  late final ApiClient apiClient = ApiClient(tokenStorage);
  late final AuthRepository authRepository = AuthRepository(apiClient, tokenStorage);
  late final UserRepository userRepository = UserRepository(apiClient);
  final catalogCache = CatalogCache();
  late final CatalogRepository catalogRepository =
      CatalogRepository(apiClient, catalogCache);
  late final KitchenRepository kitchenRepository =
      KitchenRepository(apiClient, catalogCache);
  late final CartRepository cartRepository = CartRepository(apiClient);
  late final OrderRepository orderRepository = OrderRepository(apiClient);
  late final SubscriptionRepository subscriptionRepository =
      SubscriptionRepository(apiClient);
  late final SupportRepository supportRepository = SupportRepository(apiClient);
  late final NotificationRepository notificationRepository =
      NotificationRepository(apiClient);
  late final SocketService socketService = SocketService(tokenStorage);
}
