// lib/utils/theme.dart
import 'package:flutter/material.dart';

// Color palette
const Color primaryColor = Color(0xFF1976D2);
const Color secondaryColor = Color(0xFF42A5F5);
const Color accentColor = Color(0xFFFF7043);
const Color successColor = Color(0xFF4CAF50);
const Color warningColor = Color(0xFFFF9800);
const Color errorColor = Color(0xFFF44336);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color surfaceColor = Color(0xFFFFFFFF);
const Color onPrimaryColor = Color(0xFFFFFFFF);
const Color onSecondaryColor = Color(0xFFFFFFFF);
const Color onBackgroundColor = Color(0xFF000000);
const Color onSurfaceColor = Color(0xFF000000);
const Color greyColor = Color(0xFF9E9E9E);
const Color lightGreyColor = Color(0xFFEEEEEE);

// Text styles
const TextStyle headline1 = TextStyle(
  fontSize: 32.0,
  fontWeight: FontWeight.bold,
  color: onBackgroundColor,
);

const TextStyle headline2 = TextStyle(
  fontSize: 24.0,
  fontWeight: FontWeight.bold,
  color: onBackgroundColor,
);

const TextStyle headline3 = TextStyle(
  fontSize: 20.0,
  fontWeight: FontWeight.bold,
  color: onBackgroundColor,
);

const TextStyle subtitle1 = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.w500,
  color: onBackgroundColor,
);

const TextStyle bodyText1 = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.normal,
  color: onBackgroundColor,
);

const TextStyle bodyText2 = TextStyle(
  fontSize: 14.0,
  fontWeight: FontWeight.normal,
  color: onBackgroundColor,
);

const TextStyle caption = TextStyle(
  fontSize: 12.0,
  fontWeight: FontWeight.normal,
  color: greyColor,
);

const TextStyle buttonText = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.w600,
  color: onPrimaryColor,
);

// Theme data
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  colorScheme: const ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: surfaceColor,
    background: backgroundColor,
    error: errorColor,
    onPrimary: onPrimaryColor,
    onSecondary: onSecondaryColor,
    onSurface: onSurfaceColor,
    onBackground: onBackgroundColor,
    onError: onPrimaryColor,
  ),
  scaffoldBackgroundColor: backgroundColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: onPrimaryColor,
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: onPrimaryColor,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(8),
    color: surfaceColor,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: greyColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: greyColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor),
    ),
    filled: true,
    fillColor: surfaceColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: primaryColor,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      textStyle: buttonText,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: buttonText.copyWith(color: primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: const BorderSide(color: primaryColor),
      textStyle: buttonText.copyWith(color: primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textTheme: TextTheme(
    displayLarge: headline1,
    displayMedium: headline2,
    displaySmall: headline3,
    titleMedium: subtitle1,
    bodyLarge: bodyText1,
    bodyMedium: bodyText2,
    labelSmall: caption,
  ),
  iconTheme: const IconThemeData(
    color: primaryColor,
    size: 24,
  ),
  dividerTheme: const DividerThemeData(
    color: lightGreyColor,
    thickness: 1,
    space: 1,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: Color(0xFF121212),
    background: Color(0xFF000000),
    error: errorColor,
    onPrimary: onPrimaryColor,
    onSecondary: onSecondaryColor,
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
    onError: onPrimaryColor,
  ),
  scaffoldBackgroundColor: const Color(0xFF000000),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFFFFFFFF),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(8),
    color: const Color(0xFF1E1E1E),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF616161)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF616161)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor),
    ),
    filled: true,
    fillColor: const Color(0xFF1E1E1E),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: primaryColor,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      textStyle: buttonText,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: buttonText.copyWith(color: primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: const BorderSide(color: primaryColor),
      textStyle: buttonText.copyWith(color: primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textTheme: TextTheme(
    displayLarge: headline1.copyWith(color: Color(0xFFFFFFFF)),
    displayMedium: headline2.copyWith(color: Color(0xFFFFFFFF)),
    displaySmall: headline3.copyWith(color: Color(0xFFFFFFFF)),
    titleMedium: subtitle1.copyWith(color: Color(0xFFFFFFFF)),
    bodyLarge: bodyText1.copyWith(color: Color(0xFFFFFFFF)),
    bodyMedium: bodyText2.copyWith(color: Color(0xFFFFFFFF)),
    labelSmall: caption.copyWith(color: Color(0xFFBDBDBD)),
  ),
  iconTheme: const IconThemeData(
    color: primaryColor,
    size: 24,
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF424242),
    thickness: 1,
    space: 1,
  ),
);