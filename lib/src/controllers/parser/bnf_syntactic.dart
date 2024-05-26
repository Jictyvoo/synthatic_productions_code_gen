import 'package:thenafter_dart/src/models/value/token.dart';
import 'package:thenafter_dart/src/util/helpers/string_helper.dart';
import 'package:thenafter_dart/src/util/types_util.dart';

/// Defined states for the BNF syntactic analyzer
enum SyntacticState {
  /// No sub state-machine initialized, current state is null
  nil,

  /// A production has been opened, parse data for the production
  openedProduction,

  /// A attribution has been opened, gather data for attribution
  openedAttribution
}

/// The default syntactic analyzer for a BNF grammar
class BNFSyntactic {
  final ProductionsMap _productions;

  final Map<String, String> _extraDefinitions;

  /// The current state of the parser
  SyntacticState _state;

  /// The last token in the left side
  Token _leftSideToken;

  /// The default constructor that init the object with empty list,
  /// and on the nil state
  BNFSyntactic()
      : _state = SyntacticState.nil,
        _leftSideToken = Token.empty,
        _extraDefinitions = <String, String>{},
        _productions = <String, List<List<Token>>>{};

  /// List of all productions
  ProductionsMap get productions => ProductionsMap.from(_productions);

  /// List of all extra definitions
  Map<String, String> get extraDefinitions =>
      Map<String, String>.from(_extraDefinitions);

  void _attributionState(Token token) {
    final key = StringHelper.removeQuotes(_leftSideToken.lexeme);
    final value = StringHelper.removeQuotes(token.lexeme);
    _extraDefinitions[key] = value;
    _state = SyntacticState.nil;
  }

  bool get _hasSubProduction {
    return _productions.containsKey(_leftSideToken.lexeme);
  }

  /// Return the current production list that is used
  SubProductionsList get currentProductionList {
    final productionList =
        _productions[_leftSideToken.lexeme] ?? <List<Token>>[];
    if (!_hasSubProduction) {
      _productions[_leftSideToken.lexeme] = productionList;
    }
    return productionList;
  }

  void _productionState(Token previousToken, Token token) {
    final productionList = currentProductionList;
    if (productionList.isEmpty) {
      productionList.add(<Token>[]);
    }
    final subProductions = productionList.last;
    if (token.tokenType == TokenType.operator) {
      // Check if it's another attribution and then call another state
      if (previousToken.tokenType == TokenType.variableTerminal &&
          token.lexeme == '=') {
        subProductions.removeLast();
        _discoverState(previousToken, token);
        return;
      } else if (token.lexeme == '|') {
        productionList.add(<Token>[]);
        if (subProductions.isEmpty) {
          // add empty production in case production is already empty
          subProductions.add(Token.empty);
        }
      } else if (previousToken.tokenType == TokenType.production &&
          token.lexeme == '::=') {
        if (subProductions.isNotEmpty) {
          subProductions.removeLast();
        }
        if (subProductions.isEmpty) {
          // in case last production is empty, add a empty string
          subProductions.add(Token.empty);
        }
        _leftSideToken = previousToken;

        // If the production is declared more than one time, it will add all
        // other declarations as a sub-production
        final newProduction = currentProductionList;
        if (newProduction.isNotEmpty) {
          newProduction.add(<Token>[]);
        }
      }
    } else {
      subProductions.add(token);
    }
  }

  void _delegateState(Token previousToken, Token token) {
    switch (_state) {
      case SyntacticState.openedProduction:
        return _productionState(previousToken, token);
      case SyntacticState.openedAttribution:
        return _attributionState(token);
      case SyntacticState.nil:
        break;
    }
  }

  void _discoverState(final Token previousToken, final Token token) {
    if (token.tokenType == TokenType.operator) {
      _leftSideToken = previousToken;
      if (token.lexeme == '=') {
        _state = SyntacticState.openedAttribution;
      } else if (token.lexeme == '::=') {
        if (previousToken.tokenType != TokenType.production) {
          throw ('$previousToken is not a production, please fix your grammar');
        }
        _state = SyntacticState.openedProduction;
      }
    }
  }

  /// Cleanup all elements
  void clear() {
    _state = SyntacticState.nil;
    _leftSideToken = Token.empty;
    _productions.clear();
    _extraDefinitions.clear();
  }

  /// Start parsing a token list and organize it's information
  void start(List<Token> tokenList) {
    var previousToken = Token.empty;
    iterateTokens:
    for (final token in tokenList) {
      if (token.tokenType == TokenType.comment) {
        // Skip COMMENT to not mess with syntactic analysis
        continue iterateTokens;
      }
      if (_state == SyntacticState.nil) {
        _discoverState(previousToken, token);
      } else {
        _delegateState(previousToken, token);
      }
      previousToken = token;
    }
  }
}
