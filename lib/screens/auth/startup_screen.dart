import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/customer_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/splash_screen.dart';
import '../home/dashboard_screen.dart';
import 'first_change_password_screen.dart';
import 'login_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, this.authService, this.customerService});

  final AuthService? authService;
  final CustomerService? customerService;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  late final AuthService _authService;
  late final CustomerService _customerService;
  late final bool _ownsAuthService;
  late final bool _ownsCustomerService;
  late final Future<Widget> _startupRoute;

  @override
  void initState() {
    super.initState();
    _ownsAuthService = widget.authService == null;
    _ownsCustomerService = widget.customerService == null;
    _authService = widget.authService ?? AuthService();
    _customerService = widget.customerService ?? CustomerService();
    _startupRoute = _resolveStartupRoute();
  }

  @override
  void dispose() {
    if (_ownsAuthService) _authService.dispose();
    if (_ownsCustomerService) _customerService.dispose();
    super.dispose();
  }

  Future<Widget> _resolveStartupRoute() async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) return const LoginScreen();

      if (await _authService.requiresInitialPasswordChange()) {
        return const FirstChangePasswordScreen();
      }

      final account = await _customerService.getAccount();
      unawaited(_initializeNotifications());
      return DashboardScreen(
        customerService: _customerService,
        initialAccount: account,
      );
    } on CustomerApiException catch (error) {
      if (error.statusCode == 401) {
        try {
          await _authService.clearStoredSession();
        } catch (_) {
          // A storage error should not prevent the login screen from opening.
        }
      }
      return const LoginScreen();
    } catch (_) {
      return const LoginScreen();
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService.instance.initialize(
        onOpenTransaction: (transactionId) {
          debugPrint('Transaksi yang dibuka: $transactionId');
        },
        onOpenProfile: () {
          debugPrint('Notifikasi reset PIN: membuka halaman profil.');
        },
      );
    } on Exception catch (error) {
      debugPrint('Inisialisasi notifikasi gagal: ${error.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startupRoute,
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.data!;
        return const SplashScreen();
      },
    );
  }
}
