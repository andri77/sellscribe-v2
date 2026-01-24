import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/generator/upload_screen.dart';
import '../screens/generator/details_screen.dart';
import '../screens/generator/results_screen.dart';
import '../screens/generator/edit_listing_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_edit_screen.dart';
import '../screens/settings/payment_methods_screen.dart';
import '../screens/settings/purchase_credits_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String upload = '/generator/upload';
  static const String details = '/generator/details';
  static const String results = '/generator/results';
  static const String editListing = '/generator/edit';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String profileEdit = '/settings/profile';
  static const String paymentMethods = '/settings/payment-methods';
  static const String purchaseCredits = '/settings/purchase-credits';
  
  static GoRouter createRouter(bool isAuthenticated) {
    return GoRouter(
      initialLocation: splash,
      redirect: (context, state) {
        final isLoggingIn = state.matchedLocation == login || 
                           state.matchedLocation == register;
        final isSplash = state.matchedLocation == splash;
        
        if (isSplash) return null;
        
        if (!isAuthenticated && !isLoggingIn) {
          return login;
        }
        
        if (isAuthenticated && isLoggingIn) {
          return home;
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: upload,
          builder: (context, state) => const UploadScreen(),
        ),
        GoRoute(
          path: details,
          builder: (context, state) {
            final images = state.extra as List<String>? ?? [];
            return DetailsScreen(imageUrls: images);
          },
        ),
        GoRoute(
          path: results,
          builder: (context, state) {
            final listingId = state.extra as String?;
            return ResultsScreen(listingId: listingId);
          },
        ),
        GoRoute(
          path: editListing,
          builder: (context, state) {
            final listingId = state.extra as String?;
            return EditListingScreen(listingId: listingId ?? '');
          },
        ),
        GoRoute(
          path: history,
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: profileEdit,
          builder: (context, state) => const ProfileEditScreen(),
        ),
        GoRoute(
          path: paymentMethods,
          builder: (context, state) => const PaymentMethodsScreen(),
        ),
        GoRoute(
          path: purchaseCredits,
          builder: (context, state) => const PurchaseCreditsScreen(),
        ),
      ],
    );
  }
}
