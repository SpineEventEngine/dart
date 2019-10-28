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
import 'package:dart_code_gen/src/type.dart';

import 'validator_factory.dart';

const _typeUrlToInfo = 'typeUrlToInfo';
const _defaultToTypeUrl = 'defaultToTypeUrl';
const _validators = 'validators';

const _privateTypeUrlToInfo = '_typeUrlToInfo';
const _privateDefaultToTypeUrl = '_defaultToTypeUrl';
const _privateValidators = '_validators';

const _knownTypesPart = '_KnownTypesPart';

class KnownTypesFactory {

    final Properties _properties;

    KnownTypesFactory(this._properties);

    Iterable<Spec> generateValues() {
        var typeSet = TypeSet.of(_properties.types);
        var importPrefix = _properties.importPrefix;
        var urlToBuilderMap = <Expression, Expression>{};
        var defaultToUrlMap = <Expression, Expression>{};
        for (var type in typeSet.types) {
            var typeRef = refer(type.dartClassName, "${importPrefix}/${type.dartFilePath}");
            var ctorCall = typeRef.newInstance([]);
            var builderInfoAccessor = ctorCall.property('info_');
            var typeUrl = literal(type.typeUrl);

            urlToBuilderMap[typeUrl] = builderInfoAccessor;
            defaultToUrlMap[ctorCall] = typeUrl;
        }
        var urlToBuilder = _mapField(_privateTypeUrlToInfo, _urlToInfoType, urlToBuilderMap);
        var defaultToUrl = _mapField(_privateDefaultToTypeUrl, _messageToUrlType, defaultToUrlMap);
        var validators = _createValidatorMap();
        return [urlToBuilder, defaultToUrl, validators];
    }


    Field _createValidatorMap() {
        var validatorMap = Map<Expression, Expression>();
        var typeSet = TypeSet.topLevelOnly(_properties.types);
        for (var type in typeSet.types) {
            var factory = ValidatorFactory(type.file, type.descriptor, _properties);
            var typeUrl = literalString(type.typeUrl);
            validatorMap[typeUrl] = factory.createValidator();
        }
        return _mapField(_privateValidators, _typeUrlToValidatorType, validatorMap);
    }

    Field _mapField(String name, Reference type, Map value) {
        return Field((b) => b
            ..name = name
            ..modifier = FieldModifier.final$
            ..type = type
            ..assignment = literalMap(value).code
        );
    }

    Class generateClass() {
        var typeUrlToInfo = Field((b) => b
            ..name = _typeUrlToInfo
            ..type = _urlToInfoType);
        var defaultToTypeUrl = Field((b) => b
            ..name = _defaultToTypeUrl
            ..type = _messageToUrlType);
        var validators = Field((b) => b
            ..name = _validators
            ..type = _typeUrlToValidatorType);
        
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
        var ctorCall = refer(_knownTypesPart).newInstance([refer(_privateTypeUrlToInfo),
                                                           refer(_privateDefaultToTypeUrl),
                                                           refer(_privateValidators)]);
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

    Reference get _stringType => refer('String');

    Reference get _generateMessageType => refer('GeneratedMessage', protobufImport);

    Reference get _builderInfoType => refer('BuilderInfo', protobufImport);

    Reference get _validationErrorType {
        var errorImport = validationErrorImport(_properties.standardPackage);
        return refer('ValidationError', errorImport);
    }

    Reference get _urlToInfoType => _mapType(_stringType, _builderInfoType);

    Reference get _messageToUrlType => _mapType(_generateMessageType, _stringType);

    Reference get _typeUrlToValidatorType {
        var valueType = FunctionType((b) => b
            ..requiredParameters.add(_generateMessageType)
            ..returnType = _validationErrorType);
        return _mapType(_stringType, valueType);
    }

    Reference _mapType(Reference keyType, Reference valueType) => TypeReference((b) => b
            ..symbol = 'Map'
            ..types.addAll([keyType, valueType]));
}
