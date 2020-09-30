/*
 * Copyright 2020, TeamDev. All rights reserved.
 *
 * Redistribution and use in source and/or binary forms, with or without
 * modification, must retain the above copyright notice and the following
 * disclaimer.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_code_gen/dart_code_gen.dart' as dart_code_gen;
import 'package:dart_code_gen/google/protobuf/descriptor.pb.dart';
import 'package:dart_code_gen/prebuilt_types.dart' as prebuilt;
import 'package:dart_code_gen/prebuilt_types.dart';
import 'package:dart_code_gen/spine/options.pb.dart';
import 'package:protobuf/protobuf.dart';

const String descriptorArgument = 'descriptor';
const String immutableTypesArgument = 'immutable-types';
const String destinationArgument = 'destination';
const String stdPackageArgument = 'standard-types';
const String importPrefixArgument = 'import-prefix';

const String stdoutFlag = 'stdout';
const String helpFlag = 'help';

final RegExp _importCore = RegExp('^import [\'"]dart:core[\'"] as \\\$core.+');
final RegExp _coreImportPrefix = RegExp('\\\$core\.');

/// Launches the Dart code generator.
///
main(List<String> arguments) {
    ArgParser parser = _createParser();
    var args = parser.parse(arguments);
    var help = args[helpFlag];
    if (help) {
        stdout.writeln('dart_code_gen — a command line application for generating Dart type '
                       'registries and validation code.');
        stdout.writeln(parser.usage);
    } else {
        _launch_validation_gen(args);
        _launch_proto_gen(args);
    }
}

void _launch_validation_gen(ArgResults args) {
    var descriptorPath = _getRequired(args, descriptorArgument);
    var destinationPath = _getRequired(args, destinationArgument);
    var stdPackage = args[stdPackageArgument];
    var importPrefix = args[importPrefixArgument];

    var shouldPrint = args[stdoutFlag];

    var descFile = File(descriptorPath);
    _checkExists(descFile);
    var destinationFile = File(destinationPath);
    _ensureExists(destinationFile);

    FileDescriptorSet descriptors = _parseDescriptors(descFile);
    var properties = dart_code_gen.Properties(descriptors, stdPackage, importPrefix);
    var dartCode = dart_code_gen.generate(properties);
    destinationFile.writeAsStringSync(dartCode, flush: true);
    if (shouldPrint) {
        stdout.writeln(dartCode);
    }
}

void _launch_proto_gen(ArgResults args) {
    if (!args.options.contains(immutableTypesArgument)) {
        return;
    }
    var path = args[immutableTypesArgument];
    var descriptorPath = _getRequired(args, descriptorArgument);
    var descFile = File(descriptorPath);
    _checkExists(descFile);

    var shouldPrint = args[stdoutFlag];
    FileDescriptorSet descriptors = _parseDescriptors(descFile);
    var files = prebuilt.generate(descriptors);
    for (var file in files) {
        _process_file(path, file, descriptors, shouldPrint);
    }
}

void _process_file(path, PrebuiltFile file, FileDescriptorSet descriptors, shouldPrint) {
    var destinationFile = File('${path}/${file.name}');
    _checkExists(destinationFile);
    var generatedContent = destinationFile.readAsStringSync();
    for (var sub in file.substitutions.entries) {
        var pattern = RegExp('\\b${sub.key}\\b');
        generatedContent = generatedContent.replaceAll(pattern, sub.value);
  }
    var newContent = generatedContent + file.additions;
    var lines = LineSplitter().convert(newContent);
    var sortedLines = _sortStatements(lines);
    destinationFile.writeAsStringSync(sortedLines.join('\n'), flush: true);
    if (shouldPrint) {
        stdout.writeln(file.additions);
    }
}

List<String> _sortStatements(List<String> codeLines) {
    List<String> imports = [];
    List<String> parts = [];
    List<String> otherCode = [];
    for (var line in codeLines) {
        if (line.startsWith('import') || line.startsWith('export')) {
            if (!_importCore.hasMatch(line)) {
                imports.add(line);
            }

        } else if (line.startsWith('part')) {
            parts.add(line);
        } else {
            otherCode.add(_cleanOfCorePrefix(line));
        }
    }
    return List<String>()
        ..addAll(imports)
        ..add('')
        ..addAll(parts)
        ..addAll(otherCode);
}

String _cleanOfCorePrefix(String line) {
    return line.replaceAll(_coreImportPrefix, '');
}

dynamic _getRequired(ArgResults args, String name) {
    var result = args[name];
    if (result == null) {
        throw ArgumentError('Option `$name` is required. Run with `--help` for the option list.');
    } else {
        return result;
    }
}

void _ensureExists(File file) {
  if (!file.existsSync()) {
      file.createSync(recursive: true);
  }
}

void _checkExists(File file) {
    if (!file.existsSync()) {
        throw ArgumentError('Descriptor file `${file.path}` does not exist.');
    }
}

FileDescriptorSet _parseDescriptors(File descFile) {
    var bytes = descFile.readAsBytesSync();
    ExtensionRegistry registry = _optionExtensions();
    var descriptors = FileDescriptorSet.fromBuffer(bytes, registry);
    return descriptors;
}

ExtensionRegistry _optionExtensions() {
    var registry = ExtensionRegistry();
    Options.registerAllExtensions(registry);
    return registry;
}

ArgParser _createParser() {
    var parser = ArgParser();
    parser.addOption(descriptorArgument,
                     help: 'Path to the file descriptor set file. This argument is required.');
    parser.addOption(immutableTypesArgument,
                     help: 'Path to the `lib/src` directory. This argument is required');
    parser.addOption(destinationArgument,
                     help: 'Path to the destination file. This argument is required.');
    parser.addOption(stdPackageArgument,
                     help: 'Dart package which contains the standard Google Protobuf types '
                           'and basic Spine types.',
                     defaultsTo: 'spine_client');
    parser.addOption(importPrefixArgument,
                     help: 'Path prefix for imports of types which are validated.',
                     defaultsTo: '');
    parser.addFlag(stdoutFlag,
                   defaultsTo: false,
                   negatable: true,
                   help: 'If set, the Dart code is also written into the standard output.');
    parser.addFlag(helpFlag,
                   abbr: 'h',
                   defaultsTo: false,
                   negatable: false,
                   hide: true);
    return parser;
}
