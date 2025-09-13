// lib/utils/validators.dart

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