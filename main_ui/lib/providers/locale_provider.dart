import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final savedLocale = await StorageService.getLocale();
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  void setLocale(Locale locale) {
    state = locale;
    StorageService.saveLocale(locale.languageCode);
  }
}

final localeNotifierProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());