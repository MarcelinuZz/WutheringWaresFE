String formatRupiah(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && (reverseIndex - 1) % 3 == 0) buffer.write('.');
  }
  return 'Rp${buffer.toString()}';
}

String titleCase(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

String typeLabel(String value) => switch (value.toLowerCase()) {
  'equipment' => 'Peralatan',
  'supplies' => 'Persediaan',
  _ => titleCase(value),
};
