import 'package:thenafter_dart/src/controllers/parser/lexical_helper.dart';
import 'package:thenafter_dart/src/models/value/token.dart';
import 'package:thenafter_dart/src/util/helpers/string_constants.dart';
import 'package:thenafter_dart/src/util/helpers/string_helper.dart';
import 'package:thenafter_dart/src/util/types_util.dart';

/// Default BNF lexical analyzer
class BNFLexical {
  /// A list with all tokens parsed
  final List<Token> tokenList;

  /// A list with all errors noticed
  final List<String> errorList;
  final LexicalInformation _lexicalInformation;

  /// Default constructor that initializes helper attributes
  BNFLexical()
      : tokenList = <Token>[],
        errorList = <String>[],
        _lexicalInformation = LexicalInformation();

  /// Currently this state only parse operator `::=`
  void _operatorState(int character, int previousCharacter) {
    if (previousCharacter == CHAR_COLON) {
      if (_lexicalInformation.lexemeLength == 1 && character == CHAR_COLON) {
        _lexicalInformation.addCharacter(character);
      } else if (_lexicalInformation.lexemeLength == 2 &&
          character == CHAR_EQUAL) {
        _lexicalInformation.addCharacter(character);
        tokenList.add(_lexicalInformation.generateToken(TokenType.operator));
      } else {
        errorList.add(
          'Malformed Operator '
          '`${_lexicalInformation.generateToken(TokenType.operator)}`',
        );
      }
    }
  }

  void _characterSetState(int character) {
    if (StringHelper.isNewline(character)) {
      errorList.add(
        'Malformed CharacterSet '
        '`${_lexicalInformation.generateToken(TokenType.characterSet)}`',
      );
    } else {
      _lexicalInformation.addCharacter(character);
      if (character == CHAR_CLOSE_BRACKETS) {
        tokenList.add(
          _lexicalInformation.generateToken(TokenType.characterSet),
        );
      }
    }
  }

  void _commentState(int character) {
    if (StringHelper.isNewline(character)) {
      tokenList.add(_lexicalInformation.generateToken(TokenType.comment));
    } else {
      _lexicalInformation.addCharacter(character);
    }
  }

  void _attributionState(int character) {
    if (StringHelper.isNewline(character)) {
      tokenList.add(
        _lexicalInformation.generateToken(TokenType.attributionValue),
      );
    } else {
      _lexicalInformation.addCharacter(character);
    }
  }

  void _stringState(int character, int previousCharacter) {
    _lexicalInformation.addCharacter(character);
    final firstCharacter = _lexicalInformation.firstCharacter;
    final tokenType = firstCharacter == CHAR_SINGLE_QUOTE
        ? TokenType.terminal
        // TODO: Improve string check between terminal and string
        : (_lexicalInformation.lexemeLength <= 3
            ? TokenType.terminal
            : TokenType.string);
    if (character == firstCharacter && previousCharacter != CHAR_BACK_SLASH) {
      tokenList.add(_lexicalInformation.generateToken(tokenType));
    } else if (StringHelper.isNewline(character)) {
      _lexicalInformation.addCharacter(_lexicalInformation.firstCharacter);
      tokenList.add(_lexicalInformation.generateToken(tokenType));
    }
  }

  void _productionState(int character, int previousCharacter) {
    if (!(previousCharacter == CHAR_LESS_THAN &&
        StringHelper.isWhitespace(character))) {
      _lexicalInformation.addCharacter(character);
    }
    if (StringHelper.isNewline(character)) {
      errorList.add(
        'Malformed Production '
        '`${_lexicalInformation.generateToken(TokenType.production)}`',
      );
    } else if (character == CHAR_GREATER_THAN) {
      var tokenType = TokenType.production;
      int? emptyCharacter;

      if (_lexicalInformation.lexeme == '<>') {
        tokenType = TokenType.terminal;
        emptyCharacter = 0;
      }

      tokenList.add(
        _lexicalInformation.generateToken(tokenType, emptyCharacter),
      );
    }
  }

  void _identifierState(int character) {
    if (StringHelper.isAlphanumeric(character) ||
        StringHelper.isUnderline(character)) {
      _lexicalInformation.addCharacter(character);
    } else {
      tokenList.add(
        _lexicalInformation.generateToken(TokenType.variableTerminal),
      );
      _discoverState(character);
    }
  }

  void _delegateState(int character, int previousCharacter) {
    switch (_lexicalInformation.state) {
      case LexicalStates.string:
        return _stringState(character, previousCharacter);
      case LexicalStates.production:
        return _productionState(character, previousCharacter);
      case LexicalStates.operator:
        return _operatorState(character, previousCharacter);
      case LexicalStates.identifier:
        return _identifierState(character);
      case LexicalStates.comment:
        return _commentState(character);
      case LexicalStates.attribution:
        return _attributionState(character);
      case LexicalStates.characterSet:
        return _characterSetState(character);
      case LexicalStates.nil:
        return;
    }
  }

  void _discoverState(int character) {
    if (character == CHAR_LESS_THAN) {
      // begin PRODUCTION
      _lexicalInformation.addCharacter(character);
      _lexicalInformation.state = LexicalStates.production;
    } else if (character == CHAR_COLON) {
      // begin OPERATOR
      _lexicalInformation.addCharacter(character);
      _lexicalInformation.state = LexicalStates.operator;
    } else if (character == CHAR_VERTICAL_SLASH) {
      // save VERTICAL_SLASH operator as a new Token
      tokenList.add(
        _lexicalInformation.generateToken(TokenType.operator, character),
      );
    } else if (character == CHAR_EQUAL) {
      // save EQUAL operator as a new token and  begin ATTRIBUTION
      tokenList.add(
        _lexicalInformation.generateToken(TokenType.operator, character),
      );
      _lexicalInformation.state = LexicalStates.attribution;
    } else if (character == CHAR_EXCLAMATION) {
      // begin COMMENT
      _lexicalInformation.addCharacter(character);
      _lexicalInformation.state = LexicalStates.comment;
    } else if (character == CHAR_SINGLE_QUOTE || character == CHAR_QUOTES) {
      // begin STRING
      _lexicalInformation.addCharacter(character);
      _lexicalInformation.state = LexicalStates.string;
    } else if (StringHelper.isAlphabetic(character) ||
        StringHelper.isUnderline(character)) {
      // begin IDENTIFIER
      _lexicalInformation.addCharacter(character);
      _lexicalInformation.state = LexicalStates.identifier;
    } else if (character == CHAR_OPEN_BRACKETS) {
      // begin CHARACTER_SET
      _lexicalInformation.addCharacter(character);
      _lexicalInformation.state = LexicalStates.characterSet;
    } else if (!StringHelper.isWhitespace(character) &&
        !StringHelper.isNewline(character)) {
      errorList.add(
        'Unknown symbol '
        '${_lexicalInformation.lineNumber}:${_lexicalInformation.column} '
        '`${String.fromCharCode(character)}`',
      );
    }
  }

  void _processCharacter(int character, int previousCharacter) {
    if (_lexicalInformation.state == LexicalStates.nil) {
      _discoverState(character);
    } else {
      _delegateState(character, previousCharacter);
    }
  }

  void _mainLoop(int previousCharacter, int character) {
    _lexicalInformation.column += 1;
    _processCharacter(character, previousCharacter);
    // In case line break was given with both end-line types ('\r\n'),
    // it'll subtract the counter
    if (StringHelper.isCRLF(previousCharacter, character)) {
      _lexicalInformation.lineNumber -= 1;
    }
    if (StringHelper.isNewline(character)) {
      _lexicalInformation.lineNumber += 1;
      _lexicalInformation.column = 0;
    }
  }

  /// Clear all attributes
  void clear() {
    tokenList.clear();
    errorList.clear();
    _lexicalInformation.clear();
  }

  /// Starts the parse using a iterator as input.
  /// At the end, returns all tokens identified
  List<Token> start(InputIterator input) {
    var previousCharacter = 0;
    for (final character in input) {
      _mainLoop(previousCharacter, character);
      previousCharacter = character;
    }

    // In case input end before finishing the token, force it to finish
    if (_lexicalInformation.isBuildingToken) {
      _processCharacter(CHAR_LINE_FEED, previousCharacter);
    }
    return tokenList;
  }
}
