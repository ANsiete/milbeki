import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/validators.dart';

void main() {
  group('email', () {
    test('accepts valid addresses', () {
      expect(Validators.email('ashra@example.com'), isNull);
      expect(Validators.email('  a.b@mail.co  '), isNull);
    });

    test('rejects empty or malformed addresses', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('no-at-sign'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a b@c.com'), isNotNull);
    });
  });

  group('newPassword', () {
    test('accepts 8+ characters with a letter and a number', () {
      expect(Validators.newPassword('milbeki2026'), isNull);
    });

    test('rejects short, letters-only, and digits-only passwords', () {
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('abc123'), isNotNull);
      expect(Validators.newPassword('onlyletters'), isNotNull);
      expect(Validators.newPassword('12345678'), isNotNull);
    });
  });

  group('confirmPassword', () {
    test('requires a matching value', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
      expect(Validators.confirmPassword('abc12345', 'different1'), isNotNull);
      expect(Validators.confirmPassword('', 'abc12345'), isNotNull);
    });
  });

  group('displayName', () {
    test('requires 2 to 50 characters', () {
      expect(Validators.displayName('Ashraf'), isNull);
      expect(Validators.displayName(' '), isNotNull);
      expect(Validators.displayName('A'), isNotNull);
      expect(Validators.displayName('A' * 51), isNotNull);
    });
  });

  test('loginPassword only requires something to be typed', () {
    expect(Validators.loginPassword('x'), isNull);
    expect(Validators.loginPassword(''), isNotNull);
  });
}