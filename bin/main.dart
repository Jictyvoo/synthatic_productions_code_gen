import 'dart:io';

import 'package:args/args.dart';
import 'package:thenafter_dart/thenafter_dart.dart';

import 'ast_generator_cmd.dart' as ast_generator;
import 'formatter_cmd.dart' as formatter;
import 'generator_cmd.dart' as generator;
import 'util/args_types.dart';
import 'util/output_languages.dart';
import 'util/syntactic_generator.dart';

ArgParser _configureArgParser() {
  return ArgParser()
    ..addCommand(
      ArgsCommands.generated.value,
      ArgParser()
        ..addFlag(
          GeneratedOptions.productions.value,
          abbr: GeneratedOptions.productions.abbreviation,
          help: 'During code generation, '
              'generate productions representation from .grm file',
          defaultsTo: false,
        )
        ..addFlag(
          GeneratedOptions.abstractSyntaxTree.value,
          help: 'Indicates to the tool to generate the `Abstract Syntax Tree` '
              'for the given grammar',
          defaultsTo: false,
        )
        ..addOption(
          GeneratedOptions.language.value,
          abbr: GeneratedOptions.language.abbreviation,
          help: 'Choose the output language for first, follow and productions',
          allowed: [for (final lang in OutputLanguage.values) lang.extension],
          defaultsTo: 'dart',
          mandatory: false,
        ),
    )
    ..addCommand(ArgsCommands.syntactic.value)
    ..addCommand(ArgsCommands.format.value);
}

ArgsCommands _stringToCommand(String? value) {
  for (final command in ArgsCommands.values) {
    if (command.value == value) {
      return command;
    }
  }
  return ArgsCommands.generated;
}

void main(List<String> args) {
  // configure parser, parse args and get it's values
  final argsParser = _configureArgParser();
  final argResults = argsParser.parse(args);
  final fileList = argResults.command?.rest ?? [];

  for (final fileName in fileList.isEmpty ? ['grammar.grm'] : fileList) {
    if (!fileName.endsWith('.grm')) {
      continue;
    }
    final byteLines = File(fileName).readAsStringSync();
    final startTime = DateTime.now();
    final parseResult = BNFParser().call(byteLines.codeUnits);
    final result = FirstFollow().call(
      parseResult.productionsSanitized,
      startSymbol: parseResult.startSymbol.lexeme,
    );
    print(
      'Finished in ${DateTime.now().difference(startTime).inMicroseconds} '
      'microseconds parse for file $fileName',
    );

    final commandName = _stringToCommand(argResults.command?.name);
    switch (commandName) {
      case ArgsCommands.generated:
        final genAst =
            argResults.command?[GeneratedOptions.abstractSyntaxTree.value];
        if (genAst ?? false) {
          ast_generator.execute(argResults, parseResult, result, fileName);
          return;
        }
        generator.execute(argResults, parseResult, result, fileName);
        return;
      case ArgsCommands.format:
        formatter.execute(fileName, parseResult);
        return;
      default:
        generateSyntacticFile(parseResult, result);
        return;
    }
  }
}
