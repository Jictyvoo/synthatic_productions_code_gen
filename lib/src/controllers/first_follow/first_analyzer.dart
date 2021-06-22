import 'package:thenafter_dart/src/models/value/token.dart';

import '../../util/types_util.dart';
import '../abstract_analyzer.dart';

mixin FirstAnalyzer on AbstractAnalyzer {
  SymbolSet firstOf(
    String productionName,
    ProductionsMap allProductions,
    ProductionTerminals firstList,
  ) {
    if (firstList.containsKey(productionName)) {
      return firstList[productionName]!;
    }
    final firstSet = <String>{};
    firstList[productionName] = firstSet;
    if (!allProductions.containsKey(productionName)) {
      throw ('Production "$productionName" not defined');
    }
    for (final production in allProductions[productionName]!) {
      for (var count = 0; count < production.length; count += 1) {
        if (production[count].tokenType == TokenType.production) {
          // in case first element in allProductions is a sub-production,
          // it will get the first set of it
          var firstOfSubProduction = firstOf(
            production[count].lexeme,
            allProductions,
            firstList,
          );
          joinSets(firstSet, firstOfSubProduction);
          // if sub production doesn't have a empty first, stop loop
          if (!firstOfSubProduction.contains('')) {
            count = production.length + 1;
          }
        } else {
          // if during the loop it gets a terminal symbol, add it to first set
          final token = production[count];
          firstSet.add(token.tokenType != TokenType.genericTerminal
              ? sanitizeTerminals(token.lexeme)
              : token.lexeme);
          count = production.length + 1;
        }
      }
    }

    return firstSet;
  }
}
