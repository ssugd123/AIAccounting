import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/providers/theme_provider.dart';

void main() {
  late ThemeProvider provider;

  setUp(() {
    provider = ThemeProvider();
  });

  group('ThemeProvider', () {
    test('default themeMode is ThemeMode.system', () {
      expect(provider.themeMode, ThemeMode.system);
    });

    test('isDark is false when themeMode is system', () {
      expect(provider.isDark, false);
    });

    test('toggleTheme switches dark -> light -> dark', () {
      // Start from system, toggle to dark
      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDark, true);

      // Toggle to light
      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDark, false);

      // Toggle back to dark
      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDark, true);
    });

    test('setThemeMode updates mode', () {
      provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDark, true);

      provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDark, false);

      provider.setThemeMode(ThemeMode.system);
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.isDark, false);
    });

    test('toggleTheme from light sets to dark', () {
      provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);

      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
    });
  });
}
