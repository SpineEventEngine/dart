/*
 * Copyright 2021, TeamDev. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
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

import 'package:code_builder/code_builder.dart';
import 'package:dart_code_gen/google/protobuf/descriptor.pb.dart';
import 'package:dart_code_gen/src/constraint_violation.dart';
import 'package:dart_style/dart_style.dart';

import 'src/known_types_factory.dart';

/// Code generation properties.
///
class Properties {

    /// The types to generate code for.
    final FileDescriptorSet types;

    /// The dart package containing standard Protobuf types (Google types and `base` types).
    final String standardPackage;

    /// The path prefix for Dart files generated from [types].
    final String importPrefix;

    Properties(this.types, this.standardPackage, this.importPrefix);
}

/// Generates a helper library which works with Protobuf message types compiled into Dart.
String generate(Properties properties) {
    var knownTypes = KnownTypesFactory(properties);
    var code = Library((b) =>
        b.body..add(createViolationFactory(properties.standardPackage))
              ..addAll(knownTypes.generateValues())
              ..add(knownTypes.generateClass())
              ..add(knownTypes.generateAccessor())
    );
    var emitter = DartEmitter(Allocator.simplePrefixing());
    var formatter = DartFormatter();
    return formatter.format(code.accept(emitter).toString());
}
