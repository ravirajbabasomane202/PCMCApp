// lib/utils/validators.dart
import 'package:flutter/material.dart';

String? validateRequired(String? value) {
  if (value == null || value.isEmpty) {
    return 'This field is required';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || !value.contains('@')) {
    return 'Invalid email';
  }
  return null;
}