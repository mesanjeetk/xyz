import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/files_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/file_manager_screen.dart';
import 'services/deep_link_service.dart';
import 'utils/app_theme.dart';
import 'utils/route_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize deep linking service
  // Deep linking will be initialized after router is created
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 12 Pro size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Flutter Learning App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _router,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          ),
        );
      },
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: RouteConstants.splash,
  routes: [
    GoRoute(
      path: RouteConstants.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteConstants.main,
      name: 'main',
      builder: (context, state) => const MainScreen(),
      routes: [
        GoRoute(
          path: 'home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: 'explore',
          name: 'explore',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: 'files',
          name: 'files',
          builder: (context, state) => const FileManagerScreen(),
        ),
        GoRoute(
          path: 'profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: RouteConstants.pdfViewer,
      name: 'pdfViewer',
      builder: (context, state) {
        final filePath = state.uri.queryParameters['filePath'] ?? '';
        return PDFViewerScreen(filePath: filePath);
      },
    ),
    // Deep link routes
    GoRoute(
      path: '/deep/:action',
      name: 'deepLink',
      builder: (context, state) {
        final action = state.pathParameters['action'] ?? '';
        return DeepLinkHandler(action: action);
      },
    ),
  ],
);

// Initialize deep linking with router
class _AppInitializer {
  static bool _initialized = false;
  
  static void initialize() {
    if (!_initialized) {
      DeepLinkService.instance.initialize(router: _router);
      _initialized = true;
    }
  }
}

class DeepLinkHandler extends StatelessWidget {
  final String action;
  
  const DeepLinkHandler({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    // Initialize deep linking
    _AppInitializer.initialize();
    
    // Handle different deep link actions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (action) {
        case 'home':
          context.go(RouteConstants.main);
          break;
        case 'files':
          context.go('${RouteConstants.main}/files');
          break;
        case 'profile':
          context.go('${RouteConstants.main}/profile');
          break;
        default:
          context.go(RouteConstants.main);
      }
    });
    
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}