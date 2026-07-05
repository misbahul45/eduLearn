import 'package:go_router/go_router.dart';

import '../../features/analysis/analysis_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/home/home_page.dart';
import '../../features/home/home_tab.dart';
import '../../features/profile/profile_page.dart';
import '../../features/splash/splash_page.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splashPath,
  routes: [
    GoRoute(
      path: AppRoutes.splashPath,
      name: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.loginPath,
      name: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.registerPath,
      name: AppRoutes.register,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.forgotPasswordPath,
      name: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomePage(navigationShell: navigationShell),
      branches: [
        // StatefulShellBranch(
        //   routes: [
        //     GoRoute(
        //       path: AppRoutes.homeTabPath,
        //       name: AppRoutes.homeTab,
        //       builder: (context, state) => const HomeTab(),
        //     ),
        //   ],
        // ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.chatTabPath,
              name: AppRoutes.chatTab,
              builder: (context, state) => const ChatPage(),
            ),
          ],
        ),
        // StatefulShellBranch(
        //   routes: [
        //     GoRoute(
        //       path: AppRoutes.analysisTabPath,
        //       name: AppRoutes.analysisTab,
        //       builder: (context, state) => const AnalysisPage(),
        //     ),
        //   ],
        // ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileTabPath,
              name: AppRoutes.profileTab,
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
