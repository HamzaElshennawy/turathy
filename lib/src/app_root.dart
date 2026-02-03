import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/profile/controller/theme_controller.dart';
import 'routing/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);

    // Define the custom scheme based on user request
    const FlexSchemeColor myCustomScheme = FlexSchemeColor(
      primary: Color(0xFF005D24),
      primaryContainer: Color(0xFF96D7B4), // Lighter shade for container
      secondary: Color(0xFFD9D9D9),
      secondaryContainer: Color(0xFFFFFFFF),
      tertiary: Color(
          0xFF005D24), // Using primary as tertiary for consistency or accents
      tertiaryContainer: Color(0xFF95F0FF),
      appBarColor: Color(0xFFFFFDF8), // Match background
      error: Color(0xFFB00020),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
      title: 'Barakah',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: FlexThemeData.light(
        useMaterial3: true,
        colors: myCustomScheme, // Apply custom colors
        scaffoldBackground:
            const Color(0xFFFFFDF8), // Background Color from request
        surface: const Color(
            0xFFFFFDF8), // Surface matching background often looks cleaner
        swapLegacyOnMaterial3: true,
        useMaterial3ErrorColors: true,
        fontFamily: GoogleFonts.cairo().fontFamily,
      ).copyWith(
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFDF8)
              .brighten(5)
              .withValues(alpha: .9), // Adjusted to fit background
        ),
        // Ensure bottom nav uses the correct selected color
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF005D24),
        ),
      ),
      darkTheme: FlexThemeData.dark(
        useMaterial3: true,
        scheme: theme
            .theme, // Keep default dark logic or customize if requested later
        swapLegacyOnMaterial3: true,
        useMaterial3ErrorColors: true,
        fontFamily: GoogleFonts.cairo().fontFamily,
      ),
      themeMode: theme.mode,
    );
  }
}
