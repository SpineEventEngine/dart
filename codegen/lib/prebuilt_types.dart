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

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'google/protobuf/descriptor.pb.dart';
import 'src/type.dart';

List<PrebuiltFile> generate(FileDescriptorSet descriptors) {
    var types = TypeSet.of(descriptors);
    var files = List<PrebuiltFile>();
    for (var type in types.types) {
        files.add(_generate(type));
    }
    return files;
}

PrebuiltFile _generate(MessageType type) {
    var className = type.dartClassName;
    var builderName = '${className}Builder';
    var privateCtor = Constructor((b) {
        b.name = '_';

    });
    var builderCtor = Constructor((b) {
        b.name = className;
        b.factory = true;
        b.optionalParameters.add(Parameter((param) {
            param.type = refer('void Function<$builderName>');
            param.name = 'updates';
        }));
        b.redirect = refer('_\$$className');
    });
    var cls = Class((b) {
        b.name = className;
        b.abstract = true;
        b.extend = refer('Built<$className, $builderName>');
        b.constructors
            ..add(privateCtor)
            ..add(builderCtor);
    });
    var lib = Library((b) {
        b.directives.add(Directive.import(type.dartFilePath));
        b.body.add(cls);
    });
    var emitter = DartEmitter(Allocator.simplePrefixing());
    var formatter = DartFormatter();
    var content = formatter.format(lib.accept(emitter).toString());
    return PrebuiltFile('$className.dart', content);
}

class PrebuiltFile {

    final String name;
    final String content;

    PrebuiltFile(this.name, this.content);
}
