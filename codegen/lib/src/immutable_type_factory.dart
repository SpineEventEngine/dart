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
import 'package:dart_code_gen/src/type.dart';

const _BUILT_VALUE = 'package:built_value/built_value.dart';

class ImmutableTypeFactory {

    final MessageType _type;
    final _className;

    ImmutableTypeFactory(this._type) : _className = _type.dartClassName;

    Library generate() {
        var lib = Library((b) {
            b.directives
                ..add(Directive.import(_BUILT_VALUE))
                ..add(Directive.part('$_className.proto.g.dart'));
            b.body.add(_buildClass());
        });
        return lib;
    }

    Class _buildClass() {
        var getters = _type.fields.map(_buildField);
        var builderRef = refer('${_className}Builder');
        var cls = Class((b) {
            b.name = _className;
            b.abstract = true;
            b.implements.add(_builtRef(builderRef));
            b.constructors
                ..add(_privateCtor())
                ..add(_builderCtor(builderRef));
            b.methods.addAll(getters);
        });
        return cls;
    }

    Method _buildField(FieldDeclaration field) {
        return Method((b) {
            b.name = field.escapedDartName;
            b.annotations.add(refer('nullable'));
            b.type = MethodType.getter;
            b.returns = refer('String');
        });
    }

    Reference _builtRef(Reference builderRef) {
        return TypeReference((ref) {
            ref.symbol = 'Built';
            ref.types
                ..add(refer(_className))
                ..add(builderRef);
        });
    }

    Constructor _privateCtor() {
        var privateCtor = Constructor((b) {
            b.name = '_';
        });
        return privateCtor;
    }

    Constructor _builderCtor(Reference builderRef) {
        var builderCtor = Constructor((b) {
            b.name = _className;
            b.factory = true;
            b.optionalParameters.add(Parameter((param) {
                param.type = _updatesFuncType(builderRef);
                param.name = '';
            }));
            b.redirect = refer('_\$$_className');
        });
        return builderCtor;
    }

    Reference _updatesFuncType(Reference builderRef) {
        return FunctionType((type) {
            type.requiredParameters.add(builderRef);
        });
    }
}
