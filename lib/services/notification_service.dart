import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'customer_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Jangan memproses transaksi atau PIN di background handler.
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'transaction_approval',
    'Persetujuan Transaksi',
    description: 'Notifikasi transaksi yang membutuhkan persetujuan nasabah.',
    importance: Importance.high,
  );

  void Function(int transactionId)? onOpenTransaction;
  void Function()? onOpenProfile;

  bool _listenersInitialized = false;
  String? _currentFid;

  /// Firebase Installation ID (FID) aktif yang tersimpan di perangkat.
  String? get currentFid => _currentFid;

  /// Inisialisasi notifikasi dan sinkronisasi FID setelah nasabah login.
  Future<void> initialize({
    required void Function(int transactionId) onOpenTransaction,
    void Function()? onOpenProfile,
  }) async {
    this.onOpenTransaction = onOpenTransaction;
    this.onOpenProfile = onOpenProfile;

    // 1. Meminta izin notifikasi
    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Status izin notifikasi: ${permission.authorizationStatus}',
    );

    // 2. Inisialisasi listener sistem dan stream FID (hanya sekali selama aplikasi aktif)
    if (!_listenersInitialized) {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_bank_mini'),
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          _handleNotificationTap(response.payload);
        },
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(_channel);

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage);
      }

      // Pasang listener onRegistered untuk menerima Firebase Installation ID (FID)
      _messaging.onRegistered.listen(
        (installationId) async {
          if (installationId.isNotEmpty) {
            _currentFid = installationId;
            debugPrint('[FCM] FID diterima dari Firebase.');
            await CustomerService().registerFcmToken(installationId);
          }
        },
        onError: (error) {
          debugPrint(
            '[FCM] Registrasi FID gagal: ${error.runtimeType}',
          );
        },
      );

      _listenersInitialized = true;
    }

    // 3. Sinkronkan FID ke backend untuk akun yang sedang login saat ini
    if (_currentFid != null && _currentFid!.isNotEmpty) {
      await CustomerService().registerFcmToken(_currentFid!);
    }

    try {
      await _messaging.register();
    } catch (error) {
      debugPrint('[FCM] Gagal memanggil register(): ${error.runtimeType}');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ??
        data['title']?.toString() ??
        'Notifikasi E-Teller';

    final body = notification?.body ??
        data['body']?.toString() ??
        'Ada aktivitas baru pada akun Anda.';

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_bank_mini',
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _handleRemoteMessage(RemoteMessage message) {
    _handleNotificationTap(jsonEncode(message.data));
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final type = data['type']?.toString();
      if (type == 'reset_pin') {
        onOpenProfile?.call();
        return;
      }

      final transactionId = int.tryParse(
        data['transaction_id']?.toString() ?? '',
      );

      if (transactionId != null) {
        onOpenTransaction?.call(transactionId);
        return;
      }
    } catch (_) {
      debugPrint('Payload notifikasi tidak valid.');
    }
  }
}
