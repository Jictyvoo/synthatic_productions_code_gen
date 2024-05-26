import 'string_constants.dart';

/// General string helper
abstract class StringHelper {
  /// Multiply string with given times
  static String multiplyString(String target, int quantity) {
    return target * quantity;
  }

  /// Remove quotes from the string that are in the start and the end
  static String removeQuotes(String target) {
    if (target.isEmpty) {
      return target;
    }
    final lastCharacter = target.codeUnitAt(target.length - 1);
    final firstCharacter = target.codeUnitAt(0);
    if (lastCharacter != firstCharacter ||
        !isQuotes(firstCharacter) ||
        !isQuotes(lastCharacter)) {
      return target;
    }
    // Start fixing string
    final buffer = StringBuffer();
    var openedString = 0;
    var timesClosed = 0;
    for (final character in target.runes) {
      if (openedString == 0 && isQuotes(character)) {
        openedString = character;
      } else if (character == openedString) {
        timesClosed += 1;
        openedString = 0;
      } else {
        buffer.writeCharCode(character);
      }
    }
    return timesClosed == 1 ? buffer.toString() : target;
  }

  /// Checks if the given rune represents a whitespace
  static bool isWhitespace(int rune) {
    return rune == CHAR_SPACE ||
        rune == CHAR_TAB ||
        rune == CHAR_VERTICAL_TAB ||
        rune == CHAR_FORM_FEED ||
        UNKNOWN_WHITESPACE.contains(rune);
  }

  /// Checks if the given rune represents a quote
  static bool isQuotes(int rune) {
    return rune == CHAR_SINGLE_QUOTE || rune == CHAR_QUOTES;
  }

  /// Checks if the given rune represents a whitespace
  static bool isLower(int rune) {
    return rune >= CHAR_LOWER_A && rune <= CHAR_LOWER_Z;
  }

  /// Checks if the given rune represents a upper case character
  static bool isUpper(int rune) {
    return rune >= CHAR_UPPER_A && rune <= CHAR_UPPER_Z;
  }

  /// Checks if the given rune represents a number
  static bool isNumber(int rune) {
    return rune >= CHAR_0 && rune <= CHAR_9;
  }

  /// Checks if the given rune represents a upper or lower case character
  static bool isAlphabetic(int rune) {
    return isLower(rune) || isUpper(rune);
  }

  /// Checks if the given rune is a number or a upper/lower case character
  static bool isAlphanumeric(int rune) {
    return isNumber(rune) || isAlphabetic(rune);
  }

  /// Checks if the given rune represents a underline
  static bool isUnderline(int rune) {
    return String.fromCharCode(rune) == '_';
  }

  /// Checks if the given rune represents a hyphen
  static bool isHyphen(int rune) {
    return String.fromCharCode(rune) == '-';
  }

  /// Checks if the given rune represents a new line
  static bool isNewline(int rune) {
    return String.fromCharCode(rune) == '\n' ||
        rune == CHAR_CARRIAGE_RETURN ||
        rune == CHAR_LINE_FEED;
  }

  /// Checks if the conjunction of given runes represents a CRLF new line
  static bool isCRLF(int first, int second) {
    return String.fromCharCodes([first, second]) == '\r\n';
  }

  static bool isRegex(String toReplace) {
    if (toReplace.length == 1) {
      return false;
    }
    // Patterns to identify as regex
    final regexPattern = RegExp(r'[\{\}\+\*\-\.\#\[\]\(\)\?\:\|\^\$]');

    // Check if the string contains any of the regex symbols
    return regexPattern.hasMatch(toReplace);
  }
}
