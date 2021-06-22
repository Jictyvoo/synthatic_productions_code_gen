import 'package:thenafter_dart/src/models/value/first_follow_result.dart';
import 'package:thenafter_dart/src/models/value/token.dart';

import '../util/types_util.dart';
import 'abstract_analyzer.dart';
import 'first_follow/first_analyzer.dart';
import 'first_follow/follow_analyzer.dart';

class FirstFollow extends AbstractAnalyzer with FirstAnalyzer, FollowAnalyzer {
  final Map<String, SymbolSet> allProducers;
  final ProductionTerminals firstList;
  final ProductionTerminals followList;

  FirstFollow()
      : allProducers = <String, SymbolSet>{},
        firstList = <String, SymbolSet>{},
        followList = <String, SymbolSet>{};

  /// Method to identify who produce every production in list
  void itProduces(String parentProduction, SubProductionsList subProductions) {
    for (final symbolList in subProductions) {
      for (final symbol in symbolList) {
        if (symbol.tokenType == TokenType.production) {
          final producer = allProducers[symbol] ?? <String>{};
          if (!allProducers.containsKey(symbol)) {
            allProducers[symbol.lexeme] = producer;
          }
          producer.add(parentProduction);
        }
      }
    }
  }

  FirstFollowResult start(
    ProductionsMap productions, [
    String startSymbol = '',
  ]) {
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
