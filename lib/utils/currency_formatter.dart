import 'package:flutter/services.dart';

class CurrencyFormatter {
  /// Format string digit angka menjadi pemisah ribuan titik (contoh: 50000 -> 50.000, 1000000 -> 1.000.000)
  static String formatDigits(String digits) {
    final cleanText = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return '';

    // Hapus awalan nol jika diikuti angka lain (misal '050' -> '50')
    final normalized = cleanText.replaceFirst(RegExp(r'^0+(?=[0-9])'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < normalized.length; i++) {
      if (i > 0 && (normalized.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(normalized[i]);
    }

    return buffer.toString();
  }

  /// Format double menjadi representasi mata uang Rupiah (contoh: Rp 50.000)
  static String format(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    
    final digits = absAmount.round().toString();
    final formatted = formatDigits(digits);
    return isNegative ? '-Rp $formatted' : 'Rp $formatted';
  }
}

/// Formatter otomatis saat pengguna mengetik angka di TextField, memformat titik setiap 3 digit
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final isDeleting = oldValue.text.length > newValue.text.length;
    int digitsBeforeCursor = 0;

    for (int i = 0; i < newValue.selection.end && i < newValue.text.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    // Jika pengguna menekan backspace tepat pada titik, hapus digit sebelumnya
    if (isDeleting &&
        oldValue.selection.baseOffset > 0 &&
        oldValue.selection.baseOffset <= oldValue.text.length &&
        oldValue.text[oldValue.selection.baseOffset - 1] == '.') {
      if (digitsBeforeCursor > 0) {
        digitsBeforeCursor--;
        if (digitsBeforeCursor < cleanText.length) {
          cleanText = cleanText.substring(0, digitsBeforeCursor) +
              cleanText.substring(digitsBeforeCursor + 1);
        }
      }
    }

    final formattedText = CurrencyFormatter.formatDigits(cleanText);

    // Hitung posisi kursor pada teks yang telah diformat
    int newCursorOffset = 0;
    int digitCount = 0;
    for (int i = 0; i < formattedText.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formattedText[i])) {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor) {
        newCursorOffset = i + 1;
        break;
      }
    }

    if (digitsBeforeCursor == 0) {
      newCursorOffset = 0;
    } else if (newCursorOffset > formattedText.length) {
      newCursorOffset = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}
