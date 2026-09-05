import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'screen/home_screen.dart';
import 'screen/splash_screen.dart';

void main() {
  runApp(const KiraPatrolApp());
}

class KiraPatrolApp extends StatefulWidget {
  const KiraPatrolApp({super.key});

  @override
  State<KiraPatrolApp> createState() => _KiraPatrolAppState();
}

class _KiraPatrolAppState extends State<KiraPatrolApp> { 
  late final WebViewController controller;

  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _alreadyOpenedHome = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('WEBVIEW START: $url');
          },

          onPageFinished: (url) {
            debugPrint('WEBVIEW FINISH: $url');

            if (!_alreadyOpenedHome &&
                (url.contains('/dashboard') ||
                    url.contains('/patrol/menu'))) {
              _alreadyOpenedHome = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                final navigator = navigatorKey.currentState;

                if (navigator != null) {
                  navigator.pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                }
              });
            }
          },

          onWebResourceError: (error) {
            debugPrint(
              'WEBVIEW ERROR: ${error.errorCode}',
            );

            debugPrint(
              'WEBVIEW ERROR DESC: ${error.description}',
            );

            debugPrint(
              'WEBVIEW ERROR URL: ${error.url}',
            );
          },

          onNavigationRequest: (request) {
            debugPrint(
              'WEBVIEW NAVIGATE: ${request.url}',
            );

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'http://127.0.0.1:8000/login?mobile_app=1',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'K-IKAN',
      navigatorKey: navigatorKey,

      theme: ThemeData(
        useMaterial3: true,
      ),

      home: SplashScreen(
        logoAsset: 'assets/icon/logo.png',
        appName: 'K-IKAN',
        nextScreenBuilder: (context) => Scaffold(
          body: SafeArea(
            child: WebViewWidget(
              controller: controller,
            ),
          ),
        ),
      ),
    );
  }
}