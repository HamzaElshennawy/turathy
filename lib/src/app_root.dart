/// {@category Core}
///
/// The root widget of the application.
/// 
/// [App] initializes the [MaterialApp] with the global configuration for:
/// - **Theming**: Uses [FlexColorScheme] for sophisticated light and dark themes.
/// - **Localization**: Integrates with `easy_localization` for multilingual support.
/// - **Routing**: Sets up [goRouter] for declarative navigation.
/// - **State**: Listens to [themeControllerProvider] to react to user theme preferences.
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/profile/controller/theme_controller.dart';
import 'routing/app_router.dart';

/// The top-level widget that configures the application environment.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);

    /// A custom color palette defining the core brand identity (Turathy Green).
    const FlexSchemeColor myCustomScheme = FlexSchemeColor(
      primary: Color(0xFF005D24),
      primaryContainer: Color(0xFF96D7B4),
      secondary: Color(0xFFD9D9D9),
      secondaryContainer: Color(0xFFFFFFFF),
      tertiary: Color(0xFF005D24),
      tertiaryContainer: Color(0xFF95F0FF),
      appBarColor: Color(0xFFFFFDF8),
      error: Color(0xFFB00020),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
      title: 'Turathy',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: FlexThemeData.light(
        useMaterial3: true,
        colors: myCustomScheme,
        scaffoldBackground: const Color(0xFFFFFDF8),
        surface: const Color(0xFFFFFDF8),
        swapLegacyOnMaterial3: true,
        useMaterial3ErrorColors: true,
        fontFamily: GoogleFonts.cairo().fontFamily,
      ).copyWith(
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFDF8).brighten(5).withValues(alpha: .9),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF005D24),
        ),
      ),
      darkTheme: FlexThemeData.dark(
        useMaterial3: true,
        scheme: theme.theme,
        swapLegacyOnMaterial3: true,
        useMaterial3ErrorColors: true,
        fontFamily: GoogleFonts.cairo().fontFamily,
      ),
      themeMode: theme.mode,
    );
  }
}

