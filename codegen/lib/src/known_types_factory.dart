/*
 * Copyright 2019, TeamDev. All rights reserved.
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
import 'package:dart_code_gen/dart_code_gen.dart';
import 'package:dart_code_gen/src/imports.dart';

const _typeUrlToInfo = 'typeUrlToInfo';
const _defaultToTypeUrl = 'defaultToTypeUrl';
const _validators = 'validators';

const _knownTypesPart = '_KnownTypesPart';

class KnownTypesFactory {

    final Properties _properties;

    KnownTypesFactory(this._properties);

    Class generateClass() {
        var builderInfoType = refer('BuilderInfo', protobufImport);
        var generatedMessageType = refer('GeneratedMessage', protobufImport);
        var stringType = refer('String');
        var errorImport = validationErrorImport(_properties.standardPackage);
        var validationErrorType = refer('ValidationError', errorImport);
        var validatorFunctionType = FunctionType((b) => b
            ..requiredParameters.add(generatedMessageType)
            ..returnType = validationErrorType);
        
        var typeUrlToInfo = Field((b) => b
            ..name = _typeUrlToInfo
            ..type = _mapType(stringType, builderInfoType));
        var defaultToTypeUrl = Field((b) => b
            ..name = _defaultToTypeUrl
            ..type = _mapType(generatedMessageType, stringType));
        var validators = Field((b) => b
            ..name = _validators
            ..type = _mapType(stringType, validatorFunctionType));
        
        Constructor ctor = Constructor((b) => b
            ..requiredParameters.addAll([_initParam(_typeUrlToInfo),
                                         _initParam(_defaultToTypeUrl),
                                         _initParam(_validators)])
        );
        return Class((b) { b
                ..name = _knownTypesPart
                ..constructors.add(ctor)
                ..fields.addAll([typeUrlToInfo, defaultToTypeUrl, validators]);
        });
    }

    Method generateAccessor() {
        var ctorCall = refer(_knownTypesPart).newInstance([refer(_typeUrlToInfo),
                                                           refer(_defaultToTypeUrl),
                                                           refer(_validators)]);
        return Method((b) => b
            ..name = 'types'
            ..returns = refer('dynamic')
            ..body = ctorCall.returned.statement
        );
    }
    
    Parameter _initParam(String name) {
        return Parameter((b) => b..name = name
                                 ..toThis = true);
    }

    Reference _mapType(Reference keyType, Reference valueType) => TypeReference((b) => b
            ..symbol = 'Map'
            ..types.addAll([keyType, valueType]));
}

