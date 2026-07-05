import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_cache.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/booking/data/booking_repository.dart';
import '../features/booking/domain/booking_models.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/push_service.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/domain/profile_models.dart';
import '../features/session/data/session_repository.dart';
import '../features/session/session_controller.dart';
import '../features/slots/data/marshal_repository.dart';
import '../features/slots/data/slot_repository.dart';
import '../features/slots/domain/slot_models.dart';

class AppDependencies {
  AppDependencies({
    required this.apiConfig,
    required this.apiClient,
    required this.authRepository,
    required this.sessionRepository,
    required this.slotRepository,
    required this.marshalRepository,
    required this.bookingRepository,
    required this.profileRepository,
    required this.notificationRepository,
    required this.pushService,
    required this.sessionController,
    required this.slotsCache,
    required this.bookingsCache,
    required this.profileCache,
  });

  factory AppDependencies.create() {
    final config = ApiConfig.fromEnvironment();
    final httpClient = http.Client();
    final apiClient = ApiClient(baseUri: config.baseUri, client: httpClient);

    final authRepository = ApiAuthRepository(apiClient);
    final sessionRepository = SessionRepository(
      tokenStorage: SecureTokenStorage(),
      authRepository: authRepository,
    );
    // Protected requests get tokens (and single-flight refresh) from session.
    apiClient.tokenProvider = sessionRepository;

    final profileRepository = ApiProfileRepository(apiClient);
    final sessionController = SessionController(
      sessionRepository: sessionRepository,
      profileRepository: profileRepository,
    );

    return AppDependencies(
      apiConfig: config,
      apiClient: apiClient,
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      slotRepository: ApiSlotRepository(apiClient),
      marshalRepository: ApiMarshalRepository(apiClient),
      bookingRepository: ApiBookingRepository(apiClient),
      profileRepository: profileRepository,
      notificationRepository: ApiNotificationRepository(apiClient),
      pushService: LocalFlagPushService(profileRepository),
      sessionController: sessionController,
      slotsCache: LocalCache<List<Slot>>(),
      bookingsCache: LocalCache<List<Booking>>(),
      profileCache: LocalCache<Profile>(),
    );
  }

  final ApiConfig apiConfig;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final SessionRepository sessionRepository;
  final SlotRepository slotRepository;
  final MarshalRepository marshalRepository;
  final BookingRepository bookingRepository;
  final ProfileRepository profileRepository;
  final NotificationRepository notificationRepository;
  final PushService pushService;
  final SessionController sessionController;

  /// Read-only fallback caches (Offline stale, LOGIC-008).
  final LocalCache<List<Slot>> slotsCache;
  final LocalCache<List<Booking>> bookingsCache;
  final LocalCache<Profile> profileCache;

  void dispose() {
    apiClient.close();
    sessionController.dispose();
  }
}

class AppScope extends InheritedWidget {
  const AppScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in widget tree');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return dependencies != oldWidget.dependencies;
  }
}
