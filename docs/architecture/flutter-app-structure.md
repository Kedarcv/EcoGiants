# Eco-Giants ZOU — Flutter App Structure

## Project Structure

```
lib/
├── main.dart                          # Entry point, app initialization
├── app.dart                           # MaterialApp, theme, routing
├── injection.dart                     # Dependency injection setup (get_it)
│
├── core/                              # Shared kernel / core utilities
│   ├── constants/
│   │   ├── app_constants.dart         # App-wide constants
│   │   ├── api_constants.dart         # API endpoints
│   │   └── waste_categories.dart      # Waste category definitions
│   ├── errors/
│   │   ├── exceptions.dart            # Custom exceptions
│   │   └── failures.dart              # Failure classes for BLoC
│   ├── theme/
│   │   ├── app_theme.dart             # Light/dark theme data
│   │   ├── app_colors.dart            # Color palette
│   │   └── app_typography.dart        # Text styles
│   ├── utils/
│   │   ├── validators.dart            # Form validators
│   │   ├── date_formatter.dart        # Date formatting utilities
│   │   └── image_utils.dart           # Image compression/resizing
│   └── widgets/
│       ├── app_button.dart            # Reusable button component
│       ├── app_loading_indicator.dart # Loading spinner
│       ├── app_error_widget.dart      # Error display
│       └── app_scaffold.dart          # Common scaffold
│
├── domain/                            # Domain layer (business logic)
│   ├── entities/
│   │   ├── student.dart               # Student aggregate
│   │   ├── waste_item.dart            # Waste item aggregate
│   │   ├── disposal_log.dart          # Disposal log entry
│   │   ├── bin_location.dart          # Bin location entity
│   │   ├── score.dart                 # Score aggregate
│   │   ├── eco_level.dart             # Eco level entity
│   │   ├── reward.dart                # Reward entity
│   │   └── conversation.dart          # LLM conversation
│   ├── value_objects/
│   │   ├── student_id.dart            # Student ID value object
│   │   ├── email.dart                 # Email value object
│   │   ├── points.dart                # Points value object
│   │   ├── waste_category.dart        # Waste category enum/VO
│   │   └── qr_code.dart               # QR code value object
│   ├── events/
│   │   ├── domain_event.dart          # Base domain event
│   │   ├── auth_events.dart           # Auth-related events
│   │   ├── waste_events.dart          # Waste classification events
│   │   ├── game_events.dart           # Gamification events
│   │   └── copilot_events.dart        # LLM copilot events
│   └── repositories/
│       ├── auth_repository.dart       # Auth repository interface
│       ├── waste_repository.dart      # Waste repository interface
│       ├── game_repository.dart       # Game repository interface
│       └── copilot_repository.dart    # Copilot repository interface
│
├── data/                              # Data layer (implementations)
│   ├── models/
│   │   ├── student_model.dart         # Student JSON model
│   │   ├── waste_item_model.dart      # Waste item JSON model
│   │   ├── disposal_log_model.dart    # Disposal log JSON model
│   │   ├── bin_location_model.dart    # Bin location JSON model
│   │   ├── score_model.dart           # Score JSON model
│   │   ├── eco_level_model.dart       # Eco level JSON model
│   │   ├── reward_model.dart          # Reward JSON model
│   │   └── message_model.dart         # Chat message JSON model
│   ├── repositories/
│   │   ├── auth_repository_impl.dart  # Auth repo implementation
│   │   ├── waste_repository_impl.dart # Waste repo implementation
│   │   ├── game_repository_impl.dart  # Game repo implementation
│   │   └── copilot_repository_impl.dart # Copilot repo impl
│   └── datasources/
│       ├── local/
│       │   ├── database_helper.dart   # SQLite/Hive local DB
│       │   ├── auth_local_datasource.dart
│       │   └── cache_manager.dart     # Cache management
│       └── remote/
│           ├── api_client.dart        # Dio HTTP client
│           ├── auth_remote_datasource.dart
│           ├── waste_remote_datasource.dart
│           ├── game_remote_datasource.dart
│           └── copilot_remote_datasource.dart
│
├── presentation/                      # Presentation layer (UI)
│   ├── blocs/                         # BLoC state management
│   │   ├── auth/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── camera/
│   │   │   ├── camera_bloc.dart
│   │   │   ├── camera_event.dart
│   │   │   └── camera_state.dart
│   │   ├── classification/
│   │   │   ├── classification_bloc.dart
│   │   │   ├── classification_event.dart
│   │   │   └── classification_state.dart
│   │   ├── qr_scan/
│   │   │   ├── qr_scan_bloc.dart
│   │   │   ├── qr_scan_event.dart
│   │   │   └── qr_scan_state.dart
│   │   ├── gamification/
│   │   │   ├── points_bloc.dart
│   │   │   ├── leaderboard_bloc.dart
│   │   │   └── rewards_bloc.dart
│   │   └── copilot/
│   │       ├── chat_bloc.dart
│   │       ├── chat_event.dart
│   │       └── chat_state.dart
│   ├── screens/                       # Screens (one per feature)
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart       # Main dashboard
│   │   ├── camera/
│   │   │   ├── camera_screen.dart
│   │   │   └── preview_screen.dart
│   │   ├── classification/
│   │   │   ├── result_screen.dart
│   │   │   └── manual_select_screen.dart
│   │   ├── bin_finder/
│   │   │   └── bin_detail_screen.dart
│   │   ├── qr_scan/
│   │   │   ├── qr_scanner_screen.dart
│   │   │   ├── verification_success_screen.dart
│   │   │   └── verification_failed_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   ├── leaderboard/
│   │   │   └── leaderboard_screen.dart
│   │   ├── rewards/
│   │   │   ├── rewards_catalog_screen.dart
│   │   │   └── redemption_screen.dart
│   │   ├── history/
│   │   │   └── disposal_history_screen.dart
│   │   └── copilot/
│   │       └── chat_screen.dart
│   └── widgets/                       # Reusable feature widgets
│       ├── camera/
│       │   ├── camera_overlay.dart
│       │   └── capture_button.dart
│       ├── classification/
│       │   ├── category_badge.dart
│       │   ├── confidence_meter.dart
│       │   └── factoid_card.dart
│       ├── gamification/
│       │   ├── points_display.dart
│       │   ├── eco_level_badge.dart
│       │   ├── progress_bar.dart
│       │   ├── leaderboard_item.dart
│       │   └── reward_card.dart
│       └── copilot/
│           ├── chat_bubble.dart
│           ├── quick_questions.dart
│           └── typing_indicator.dart
│
├── services/                          # App-wide services
│   ├── navigation_service.dart        # Navigation helpers
│   ├── notification_service.dart      # Push notifications
│   └── connectivity_service.dart      # Network state
│
└── config/                            # Configuration
    ├── routes.dart                    # GoRouter route definitions
    └── env.dart                       # Environment variables
```

---

## State Management (BLoC Pattern)

```dart
// Example: Classification BLoC
class ClassificationBloc extends Bloc<ClassificationEvent, ClassificationState> {
  final WasteRepository _wasteRepository;
  final ImagePicker _imagePicker;

  ClassificationBloc({
    required WasteRepository wasteRepository,
    required ImagePicker imagePicker,
  })  : _wasteRepository = wasteRepository,
        _imagePicker = imagePicker,
        super(ClassificationInitial()) {
    on<PickImageEvent>(_onPickImage);
    on<ClassifyImageEvent>(_onClassifyImage);
    on<SelectManualCategoryEvent>(_onSelectManualCategory);
  }

  Future<void> _onClassifyImage(
    ClassifyImageEvent event,
    Emitter<ClassificationState> emit,
  ) async {
    emit(ClassificationLoading());
    
    final result = await _wasteRepository.classifyImage(event.imagePath);
    
    result.fold(
      (failure) => emit(ClassificationError(failure.message)),
      (classification) => emit(ClassificationSuccess(classification)),
    );
  }
}

// States
abstract class ClassificationState {}
class ClassificationInitial extends ClassificationState {}
class ClassificationLoading extends ClassificationState {}
class ClassificationSuccess extends ClassificationState {
  final WasteClassification classification;
  ClassificationSuccess(this.classification);
}
class ClassificationError extends ClassificationState {
  final String message;
  ClassificationError(this.message);
}
```

---

## Dependency Injection Setup

```dart
// injection.dart
final getIt = GetIt.instance;

void configureDependencies() {
  // External packages
  getIt.registerLazySingleton(() => Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
  )));
  getIt.registerLazySingleton(() => ImagePicker());
  getIt.registerLazySingleton(() => MobileScannerController());

  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<WasteRemoteDataSource>(
    () => WasteRemoteDataSourceImpl(getIt<Dio>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );
  getIt.registerLazySingleton<WasteRepository>(
    () => WasteRepositoryImpl(getIt<WasteRemoteDataSource>()),
  );

  // BLoCs
  getIt.registerFactory(() => AuthBloc(authRepository: getIt<AuthRepository>()));
  getIt.registerFactory(() => ClassificationBloc(
    wasteRepository: getIt<WasteRepository>(),
    imagePicker: getIt<ImagePicker>(),
  ));
}
```

---

## Routing Configuration

```dart
// config/routes.dart
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(path: 'camera', builder: (_, __) => const CameraScreen()),
        GoRoute(path: 'result', builder: (_, __) => const ResultScreen()),
        GoRoute(path: 'qr-scan', builder: (_, __) => const QrScannerScreen()),
        GoRoute(path: 'leaderboard', builder: (_, __) => const LeaderboardScreen()),
        GoRoute(path: 'rewards', builder: (_, __) => const RewardsCatalogScreen()),
        GoRoute(path: 'history', builder: (_, __) => const DisposalHistoryScreen()),
        GoRoute(path: 'copilot', builder: (_, __) => const ChatScreen()),
        GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);
```

---

## Theme Design

### Color Palette
```dart
class AppColors {
  // Primary
  static const Color primary = Color(0xFF2E7D32);        // Eco Green
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF66BB6A);
  
  // Waste Categories
  static const Color recyclable = Color(0xFF2196F3);     // Blue
  static const Color organic = Color(0xFF8BC34A);        // Light Green
  static const Color eWaste = Color(0xFFFF9800);         // Orange
  static const Color general = Color(0xFF9E9E9E);        // Grey
  static const Color hazardous = Color(0xFFF44336);      // Red
  
  // Gamification
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  
  // UI
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF212121);
}
```

### Typography
```dart
class AppTypography {
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
  );
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.onBackground,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );
}
```

---

*Document Version: 1.0*
*Last Updated: 27 July 2026*
