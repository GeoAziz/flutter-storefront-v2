import 'package:flutter/material.dart';
import 'package:shop/entry_point.dart';
import 'package:shop/screens/admin/admin_dashboard.dart';

import 'screen_export.dart';
import 'route_names.dart';

// Yuo will get 50+ screens and more once you have the full template
// 🔗 Full template: https://theflutterway.gumroad.com/l/fluttershop

// NotificationPermissionScreen()
// PreferredLanguageScreen()
// SelectLanguageScreen()
// SignUpVerificationScreen()
// ProfileSetupScreen()
// VerificationMethodScreen()
// OtpScreen()
// SetNewPasswordScreen()
// DoneResetPasswordScreen()
// TermsOfServicesScreen()
// SetupFingerprintScreen()
// SetupFingerprintScreen()
// SetupFingerprintScreen()
// SetupFingerprintScreen()
// SetupFaceIdScreen()
// OnSaleScreen()
// BannerLStyle2()
// BannerLStyle3()
// BannerLStyle4()
// SearchScreen()
// SearchHistoryScreen()
// NotificationsScreen()
// EnableNotificationScreen()
// NoNotificationScreen()
// NotificationOptionsScreen()
// ProductInfoScreen()
// ShippingMethodsScreen()
// ProductReviewsScreen()
// SizeGuideScreen()
// BrandScreen()
// CartScreen()
// EmptyCartScreen()
// PaymentMethodScreen()
// ThanksForOrderScreen()
// CurrentPasswordScreen()
// EditUserInfoScreen()
// OrdersScreen()
// OrderProcessingScreen()
// OrderDetailsScreen()
// CancleOrderScreen()
// DelivereOrdersdScreen()
// AddressesScreen()
// NoAddressScreen()
// AddNewAddressScreen()
// ServerErrorScreen()
// NoInternetScreen()
// ChatScreen()
// DiscoverWithImageScreen()
// SubDiscoverScreen()
// AddNewCardScreen()
// EmptyPaymentScreen()
// GetHelpScreen()

// ℹ️ All the comments screen are included in the full template
// 🔗 Full template: https://theflutterway.gumroad.com/l/fluttershop

Route<dynamic> generateRoute(RouteSettings settings) {
  // Normalize incoming names to a leading-slash form so callers can use
  // either 'home' or '/home' and remain compatible.
  final String routeName =
      (settings.name != null && settings.name!.startsWith('/'))
          ? settings.name!
          : '/${settings.name ?? ''}';

  switch (routeName) {
    case RouteNames.onboarding:
      return MaterialPageRoute(
        builder: (context) => const OnBordingScreen(),
      );
    case RouteNames.login:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    case RouteNames.signup:
      return MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      );
    case RouteNames.passwordRecovery:
      return MaterialPageRoute(
        builder: (context) => const PasswordRecoveryScreen(),
      );
    case RouteNames.productDetails:
      return MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(),
      );
    case RouteNames.productDetail:
      return MaterialPageRoute(
        builder: (context) => const ProductDetailScreen(),
        settings: settings,
      );
    case RouteNames.allProducts:
      return MaterialPageRoute(
        builder: (context) => const AllProductsScreen(),
      );
    case RouteNames.productReviews:
      return MaterialPageRoute(
        builder: (context) => const ProductReviewsScreen(),
      );
    case RouteNames.home:
      return MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      );
    case RouteNames.discover:
      return MaterialPageRoute(
        builder: (context) => const DiscoverScreen(),
      );
    case RouteNames.onSale:
      return MaterialPageRoute(
        builder: (context) => const OnSaleScreen(),
      );
    case RouteNames.kids:
      return MaterialPageRoute(
        builder: (context) => const KidsScreen(),
      );
    case RouteNames.search:
      return MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      );
    case RouteNames.bookmark:
      return MaterialPageRoute(
        builder: (context) => const BookmarkScreen(),
      );
    case RouteNames.entryPoint:
      return MaterialPageRoute(
        builder: (context) => const EntryPoint(),
      );
    case RouteNames.adminDashboard:
      return MaterialPageRoute(
        builder: (context) => const AdminDashboardScreen(),
      );
    case RouteNames.profile:
      return MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      );
    case RouteNames.userInfo:
      return MaterialPageRoute(
        builder: (context) => const UserInfoScreen(),
      );
    case RouteNames.notifications:
      return MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      );
    case RouteNames.noNotifications:
      return MaterialPageRoute(
        builder: (context) => const NoNotificationScreen(),
      );
    case RouteNames.enableNotifications:
      return MaterialPageRoute(
        builder: (context) => const EnableNotificationScreen(),
      );
    case RouteNames.notificationOptions:
      return MaterialPageRoute(
        builder: (context) => const NotificationOptionsScreen(),
      );
    case RouteNames.addresses:
      return MaterialPageRoute(
        builder: (context) => const AddressesScreen(),
      );
    case RouteNames.orders:
      return MaterialPageRoute(
        builder: (context) => const OrdersScreen(),
      );
    case RouteNames.preferences:
      return MaterialPageRoute(
        builder: (context) => const PreferencesScreen(),
      );
    case RouteNames.emptyWallet:
      return MaterialPageRoute(
        builder: (context) => const EmptyWalletScreen(),
      );
    case RouteNames.wallet:
      return MaterialPageRoute(
        builder: (context) => const WalletScreen(),
      );
    case RouteNames.cart:
      return MaterialPageRoute(
        builder: (context) => const CartScreen(),
      );
    case RouteNames.paymentMethod:
      return MaterialPageRoute(
        builder: (context) => const PaymentMethodScreen(),
      );
    // (Legacy commented cases removed — router now matches canonical RouteNames.)
    default:
      return MaterialPageRoute(
        // Make a screen for undefined routes — fall back to onboarding
        builder: (context) => const OnBordingScreen(),
      );
  }
}
