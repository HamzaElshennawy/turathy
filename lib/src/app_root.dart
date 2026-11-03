/// {@category Core}
///
/// The root widget of the application.
///
/// [App] initializes the [MaterialApp] with the global configuration for:
/// - **Theming**: Uses [FlexColorScheme] for sophisticated light and dark themes.
/// - **Localization**: Integrates with `easy_localization` for multilingual support.
/// - **Routing**: Sets up [goRouter] for declarative navigation.
/// - **State**: Listens to [themeControllerProvider] to react to user theme preferences.
import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/live_activity/live_activity_bootstrap.dart';
import 'features/profile/controller/theme_controller.dart';
import 'features/settings/data/app_config_repository.dart';
import 'routing/app_router.dart';

/// The top-level widget that configures the application environment.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final config = ref.watch(appConfigProvider).valueOrNull;
    final brand = _colorFromHex(config?.occasionColor);

    final FlexSchemeColor myCustomScheme = FlexSchemeColor(
      primary: brand,
      primaryContainer: const Color(0xFF96D7B4),
      secondary: const Color(0xFFD9D9D9),
      secondaryContainer: const Color(0xFFFFFFFF),
      tertiary: brand,
      tertiaryContainer: const Color(0xFF95F0FF),
      appBarColor: const Color(0xFFFFFDF8),
      error: const Color(0xFFB00020),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
      title: 'Alturath Aljmeel Co.',
      localizationsDelegates: [
        CountryLocalizations.delegate,
        ...context.localizationDelegates,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme:
          FlexThemeData.light(
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
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: brand,
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
      builder: (context, child) {
        return LiveActivityBootstrap(
          child: Actions(
            actions: <Type, Action<Intent>>{
              EditableTextTapOutsideIntent:
                  CallbackAction<EditableTextTapOutsideIntent>(
                    onInvoke: (intent) => null,
                  ),
            },
            child: _OccasionFrame(
              color: brand,
              logoUrl: config?.occasionLogoUrl,
              bannerUrl: config?.occasionBannerUrl,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

Color _colorFromHex(String? raw) {
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(raw?.trim() ?? '');
  if (match == null) return const Color(0xFF005D24);
  return Color(int.parse('FF${match.group(1)}', radix: 16));
}

class _OccasionFrame extends StatelessWidget {
  const _OccasionFrame({
    required this.color,
    required this.child,
    this.logoUrl,
    this.bannerUrl,
  });

  final Color color;
  final String? logoUrl;
  final String? bannerUrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final showBar =
        (logoUrl != null && logoUrl!.isNotEmpty) ||
        (bannerUrl != null && bannerUrl!.isNotEmpty);
    if (!showBar) return child;
    return Column(
      children: [
        Material(
          color: color,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Row(
                children: [
                  if (logoUrl != null && logoUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Image.network(
                        logoUrl!,
                        height: 36,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  if (bannerUrl != null && bannerUrl!.isNotEmpty)
                    Expanded(
                      child: Image.network(
                        bannerUrl!,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
