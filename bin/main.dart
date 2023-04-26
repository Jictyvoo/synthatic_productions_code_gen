import 'dart:io';

import 'package:args/args.dart';
import 'package:thenafter_dart/thenafter_dart.dart';

import 'controllers/delegate_generator_language.dart';
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
        ..addOption(
          GeneratedOptions.language.value,
          abbr: GeneratedOptions.language.abbreviation,
          help: 'Choose the output language for first, follow and productions',
          defaultsTo: 'dart',
          mandatory: false,
        ),
    )
    ..addCommand(ArgsCommands.syntactic.value);
}

ArgsCommands _stringToCommand(String? value) {
  for (final command in ArgsCommands.values) {
    if (command.value == value) {
      return command;
    }
  }
  return ArgsCommands.generated;
}

OutputLanguage _stringToLanguage(String value) {
  for (final language in OutputLanguage.values) {
    if (language.name == value || language.extension == value) {
      return language;
    }
  }
  return OutputLanguage.dart;
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
    final byteLines = File(fileName).readAsBytesSync();
    final startTime = DateTime.now();
    final parseResult = BNFParser().call(byteLines);
    final result = FirstFollow().call(
      parseResult.productions,
      parseResult.startSymbol.lexeme,
    );
    print(
      'Finished in ${DateTime.now().difference(startTime).inMicroseconds} '
      'microseconds parse for file $fileName',
    );
    final commandName = _stringToCommand(argResults.command?.name);
    if (commandName == ArgsCommands.generated) {
      final generateProductions =
          argResults.command?[GeneratedOptions.productions.value] ?? false;
      final outputLanguage =
          argResults.command?[GeneratedOptions.language.value] ?? 'lua';
      final selectedLanguage = _stringToLanguage(outputLanguage);
      final contentsBuffer = generateFileContents(
        selectedLanguage,
        parseResult,
        result,
        generateProductions,
      );
      final file = File('$fileName.${selectedLanguage.extension}');
      file.writeAsStringSync(contentsBuffer.toString());
    } else {
      generateSyntacticFile(parseResult, result);
    }
  }
}
