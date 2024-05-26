import 'package:thenafter_dart/src/models/value/first_follow_result.dart';
import 'package:thenafter_dart/src/models/value/token.dart';

import '../util/types_util.dart';
import 'abstract_analyzer.dart';
import 'first_follow/first_analyzer.dart';
import 'first_follow/follow_analyzer.dart';

/// The FirstFollow default analyzer for a given productions map
class FirstFollow extends AbstractAnalyzer with FirstAnalyzer, FollowAnalyzer {
  /// Holds information about which each productions produces.
  ///
  /// If a production is "<A> := <B> <C> | <D>";
  /// This attribute with have a map of sets like: "<A>: {'<B>', '<C>', '<D>'}"
  final Map<String, SymbolSet> allProducers;

  /// A Map containing the list of first terminals for each production
  final ProductionTerminals firstList;

  /// A Map containing the list of follow terminals for each production
  final ProductionTerminals followList;

  /// Default constructor for the first and follow analyzer, it initializes
  /// all required fields with empty maps
  FirstFollow()
      : allProducers = <String, SymbolSet>{},
        firstList = <String, SymbolSet>{},
        followList = <String, SymbolSet>{};

  /// Method to identify who produce every production in list
  void itProduces(String parentProduction, SubProductionsList subProductions) {
    for (final symbolList in subProductions) {
      for (final symbol in symbolList) {
        if (symbol.tokenType == TokenType.production) {
          final producer = allProducers[symbol.lexeme] ?? <String>{};
          if (!allProducers.containsKey(symbol.lexeme)) {
            allProducers[symbol.lexeme] = producer;
          }
          producer.add(parentProduction);
        }
      }
    }
  }

  /// With a given [ProductionsMap] and startSymbol, the algorithm starts to
  /// calculate the first and follow sets
  FirstFollowResult call(
    ProductionsMap productions, {
    String startSymbol = '',
  }) {
    firstList.clear();
    followList.clear();
    followList[startSymbol] = <String>{"'\$'"};
    for (final entry in productions.entries) {
      itProduces(entry.key, entry.value);
      firstOf(entry.key, productions, firstList);
    }
    followLoop:
    for (final entry in productions.entries) {
      if (entry.key == startSymbol) {
        continue followLoop;
      }
      followOf(
        entry.key,
        productions,
        followList: followList,
        hasToo: <String>{},
        firstList: firstList,
        allProducers: allProducers,
      );
    }
    return FirstFollowResult(firstList, followList);
  }
}
