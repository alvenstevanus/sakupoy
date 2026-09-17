import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakupoy/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('Format nilai 0', () {
      expect(CurrencyFormatter.format(0), 'Rp 0');
    });

    test('Format ribuan', () {
      expect(CurrencyFormatter.format(5000), 'Rp 5.000');
    });

    test('Format puluhan ribu', () {
      expect(CurrencyFormatter.format(50000), 'Rp 50.000');
    });

    test('Format jutaan', () {
      expect(CurrencyFormatter.format(1500000), 'Rp 1.500.000');
    });

    test('Format nilai negatif', () {
      expect(CurrencyFormatter.format(-25000), '-Rp 25.000');
    });

    test('formatDigits memisahkan titik setiap 3 digit sesuai contoh user', () {
      expect(CurrencyFormatter.formatDigits('50000'), '50.000');
      expect(CurrencyFormatter.formatDigits('1000000'), '1.000.000');
      expect(CurrencyFormatter.formatDigits('123456'), '123.456');
    });
  });

  group('ThousandsSeparatorInputFormatter Tests', () {
    final formatter = ThousandsSeparatorInputFormatter();

    test('Memformat otomatis input saat diketik', () {
      // Input: 50000 -> 50.000
      final result1 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '50000',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(result1.text, '50.000');
      expect(result1.selection.baseOffset, 6);

      // Input: 1000000 -> 1.000.000
      final result2 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1000000',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      expect(result2.text, '1.000.000');
      expect(result2.selection.baseOffset, 9);

      // Input: 123456 -> 123.456
      final result3 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '123456',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(result3.text, '123.456');
      expect(result3.selection.baseOffset, 7);
    });

    test('Menangani input kosong atau hapus', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '5.000'),
        const TextEditingValue(text: ''),
      );
      expect(result.text, '');
    });
  });
}
