String? validateEmail(String email) {
  final value = email.trim();
  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (value.isEmpty) return 'Email wajib diisi.';
  if (!pattern.hasMatch(value)) return 'Format email tidak valid.';
  return null;
}

String? validatePassword(String password) {
  if (password.isEmpty) return 'Password wajib diisi.';
  if (password.length < 8) return 'Password minimal 8 karakter.';
  return null;
}
