import 'package:test/test.dart';
import 'package:thenafter_dart/src/util/helpers/string_constants.dart';
import 'package:thenafter_dart/src/util/helpers/string_helper.dart';

void main() {
  test('test multiply string', () {
    expect(StringHelper.multiplyString('hello', 0), '');
    expect(StringHelper.multiplyString('abc', 3), 'abcabcabc');
    expect(StringHelper.multiplyString('xyz', -2), '');
    expect(StringHelper.multiplyString('', 5), '');
    expect(StringHelper.multiplyString('test', 1), 'test');
  });

  testRemoveQuotes();
  test('test if detect whitespace correctly', testCheckWhitespace);
  group('StringHelper.isNotRegex', () {
    test('should identify regex-like strings correctly', () {
      expect(StringHelper.isRegex("{Alphanumeric} + ['_"), isTrue);
      expect(StringHelper.isRegex('{#32..#126} - {#34}'), isTrue);
      expect(StringHelper.isRegex("{Digit}+('.'{Digit}+)"), isTrue);
      expect(StringHelper.isRegex("'\"'{simbolo}'\"'"), isTrue);
      expect(StringHelper.isRegex("'\"'{simbolo}*'\"'"), isTrue);
      expect(StringHelper.isRegex('{Letter}{corpoidentificador}*'), isTrue);
      /*expect(StringHelper.isNotRegex('This is a normal string.'), isTrue);
      expect(
        StringHelper.isNotRegex('Just text without special regex symbols'),
        isTrue,
      );*/
    });
  });
}

void testCheckWhitespace() {
  for (final character in ' \t'.codeUnits) {
    expect(StringHelper.isWhitespace(character), true);
  }
  final buffer = StringBuffer();
  for (var value = CHAR_LOWER_A; value <= CHAR_LOWER_Z; value++) {
    buffer.writeCharCode(value);
  }

  final nonWhitespace = buffer.toString() + buffer.toString().toUpperCase();
  for (final character in nonWhitespace.codeUnits) {
    expect(StringHelper.isWhitespace(character), false);
  }
}

void testRemoveQuotes() {
  test(
      'Test removing quotes from a string that has quotes at the start and end',
      () {
    expect(StringHelper.removeQuotes('"Hello World"'), 'Hello World');
  });

  test(
    "Test removing quotes from a string that doesn't "
    'have quotes at the start and end',
    () {
      expect(StringHelper.removeQuotes('Hello World'), 'Hello World');
    },
  );
  test(
    'Test removing quotes from a string that has only one quote at the end',
    () {
      expect(StringHelper.removeQuotes('Hello World"'), 'Hello World"');
    },
  );
  test(
    'Test removing quotes from an empty string',
    () {
      expect(StringHelper.removeQuotes(''), '');
    },
  );
  test(
    'Test removing quotes from a string that has multiple quotes',
    () {
      expect(
        StringHelper.removeQuotes('\'He said, "Hello World"\''),
        'He said, "Hello World"',
      );
    },
  );
}
