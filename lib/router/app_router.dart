import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/document_model.dart';
import '../screens/auto_signature_screen.dart';
import '../screens/document_detail_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/draw_signature_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding_screen.dart';
import '../screens/scan_signature_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sign_place_screen.dart';
import '../screens/sign_preview_screen.dart';
import '../screens/sign_success_screen.dart';
import '../screens/sign_upload_screen.dart';
import '../screens/signatures_screen.dart';
import '../screens/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/draw-signature',
        name: 'drawSignature',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DrawSignatureScreen(),
      ),
      GoRoute(
        path: '/scan-signature',
        name: 'scanSignature',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScanSignatureScreen(),
      ),
      GoRoute(
        path: '/auto-signature',
        name: 'autoSignature',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AutoSignatureScreen(),
      ),
      GoRoute(
        path: '/sign-document',
        name: 'signDocument',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignUploadScreen(),
        routes: [
          GoRoute(
            path: 'preview',
            name: 'signPreview',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SignPreviewScreen(),
          ),
          GoRoute(
            path: 'place',
            name: 'signPlace',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SignPlaceScreen(),
          ),
          GoRoute(
            path: 'success',
            name: 'signSuccess',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SignSuccessScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/signatures',
                name: 'signatures',
                builder: (context, state) => const SignaturesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                name: 'documents',
                builder: (context, state) => const DocumentsScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    name: 'documentDetail',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final extra = state.extra;
                      return DocumentDetailScreen(
                        documentId: id,
                        document: extra is DocumentModel ? extra : null,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
