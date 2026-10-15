import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:zecorner/core/auth/auth_session_storage.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/cubit/user_profile_cubit.dart';
import 'package:zecorner/infrastructure/users/user_profile_repository.dart';
import 'package:zecorner/core/cubit/task_cubit.dart';
import 'package:zecorner/core/cubit/note_cubit.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
// import 'package:zecorner/core/network/api_network_inspector.dart';
import 'package:zecorner/core/network/dio_client.dart';
import 'package:zecorner/core/network/network_info_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/services/local_device_notification_service.dart';
import 'package:zecorner/core/widgets/app_update_bootstrap.dart';
import 'package:zecorner/core/widgets/notification_bootstrap.dart';
import 'package:zecorner/core/widgets/session_expired_bootstrap.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';
import 'package:zecorner/presentation/widgets/status/login_intro_loader.dart';
import 'package:zecorner/router/app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppFrameworkErrorView(
        details: kDebugMode ? details.exceptionAsString() : null,
      ),
    );
  };
  await Future.delayed(const Duration(milliseconds: 50));

  try {
    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
      print('Environment variables loaded successfully');
    } catch (e) {
      print('Env loading error: $e');
    }

    // ApiNetworkInspector.configure(); // API debug — geri açmak için yorumu kaldır

    // Initialize DioClient
    DioClient().init();

    // SharedPreferences'i initialize et
    try {
      await SharedPreferences.getInstance();
      await AuthSessionStorage.enforceCurrentEpoch();
      print('SharedPreferences initialized successfully');
    } catch (e) {
      print('SharedPreferences initialization error: $e');
    }

    try {
      await LocalDeviceNotificationService.instance.initialize();
    } catch (e) {
      print('Local notifications init error: $e');
    }

    runApp(const MyApp());
    print('MyApp started');
  } catch (e, stack) {
    print('Uygulama başlatma hatası: $e');
    print('Stack: $stack');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit()..initializeAuth(),
        ),
        BlocProvider<UserProfileCubit>(
          create: (context) => UserProfileCubit(
            userProfileRepository: UserProfileRepository(
              dio: DioClient().dio,
              networkInfo: NetworkInfoImpl(),
            ),
          ),
        ),
        BlocProvider<TaskCubit>(
          create: (context) => TaskCubit(),
        ),
        BlocProvider<NoteCubit>(
          create: (context) => NoteCubit(),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) {
          if (current is AuthUnauthenticated) return previous is! AuthUnauthenticated;
          if (current is AuthAuthenticated && previous is AuthAuthenticated) {
            return current.user.id != previous.user.id;
          }
          return false;
        },
        listener: (context, state) {
          context.read<UserProfileCubit>().clearState();
          context.read<TaskCubit>().reset();
          context.read<NoteCubit>().reset();
          RoleSidebar.clearSidebarCache();
          LoginIntroGate.arm();
        },
        child: SessionExpiredBootstrap(
        child: NotificationBootstrap(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => AppUpdateBootstrap(
              child: child ?? const SizedBox.shrink(),
            ),
            // API Network Inspector (debug) — geri açmak için aşağıdaki builder'ı kullan:
            // builder: (context, child) {
            //   if (!kDebugMode || child == null) {
            //     return child ?? const SizedBox.shrink();
            //   }
            //   return ApiNetworkInspectorListener(
            //     child: Stack(
            //       fit: StackFit.expand,
            //       children: [
            //         child,
            //         const ApiNetworkInspectorButton(),
            //       ],
            //     ),
            //   );
            // },
            title: 'Zecorner Test',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
              canvasColor: Colors.white,
            ),
            locale: const Locale('tr', 'TR'),
            supportedLocales: const [
              Locale('tr', 'TR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRouter.appEntry,
            routes: AppRouter.routes,
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => AppStatusPage.notFound(
                  onRetry: () {
                    final nav = Navigator.of(context);
                    if (nav.canPop()) {
                      nav.pop();
                    } else {
                      nav.pushNamedAndRemoveUntil(
                        AppRouter.homeListings,
                        (route) => false,
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppStatusPage.error(
        title: 'Uygulama başlatılırken hata oluştu',
        message: 'Lütfen uygulamayı kapatıp yeniden açın.',
        showHomeButton: false,
      ),
    );
  }
}
