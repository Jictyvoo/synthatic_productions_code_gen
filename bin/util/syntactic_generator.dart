import 'dart:io';

import 'package:thenafter_dart/generators.dart';
import 'package:thenafter_dart/thenafter_dart.dart';

void generateSyntacticFile(
  GrammarInformation parseResult,
  FirstFollowResult result,
) {
  final generator = SyntacticPythonGenerator();
  final fileBuffer = StringBuffer();
  final givenInfo = <String, String>{
    'Identifier': 'TokenTypes.IDENTIFIER',
    'DecLiteral': 'TokenTypes.NUMBER',
    'OctLiteral': 'TokenTypes.NUMBER',
    'HexLiteral': 'TokenTypes.NUMBER',
    'FloatLiteral': 'TokenTypes.NUMBER',
    'StringLiteral': 'TokenTypes.STRING',
  };
  generator.buildNeededImports(fileBuffer);
  generator.buildTypeDeclarations(fileBuffer);
  for (final currentProduction in parseResult.productionsSanitized.entries) {
    fileBuffer.writeln(
      generator.buildFunction(
        currentProduction.key,
        currentProduction.value,
        result.firstList,
        givenInfo,
      ),
    );
  }

  final file = File('./syntactic_productions.log');
  file.writeAsStringSync(fileBuffer.toString());
}
