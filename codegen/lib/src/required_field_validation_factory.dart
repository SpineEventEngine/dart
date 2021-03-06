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
import 'package:dart_code_gen/src/type.dart';

import 'constraint_violation.dart';
import 'field_validator_factory.dart';
import 'validator_factory.dart';

/// A factory of validation code for combinations of fields.
/// 
/// Generates validation code for checking the `(required_field)` constraint.
/// 
class RequiredFieldValidatorFactory {

    final ValidatorFactory _validator;
    final List<_Combination> _combinations;
    final ViolationConsumer _consumer;

    RequiredFieldValidatorFactory._(this._validator, this._combinations, this._consumer);

    factory RequiredFieldValidatorFactory.forExpression(String boolExpression,
                                                        ValidatorFactory validator,
                                                        ViolationConsumer consumer) {
        var combinations = boolExpression
            .split('|')
            .map((c) => c.split('&'))
            .map((fields) => _Combination.ofFields(fields, validator))
            .toList();
        return RequiredFieldValidatorFactory._(validator, combinations, consumer);
    }

    Code generate() {
        if (_combinations.length == 0) {
            return Code("");
        }
        var violationInit = violationRef.call([literalString('Required fields must be set.'),
                                               literalString(_validator.fullTypeName),
                                               literalList([])]);
        var reportViolation = _consumer(violationInit);
        var expression = _combinations
            .map((c) => c.notSetCondition())
            .reduce((l, r) => l.and(r))
            .conditional(reportViolation, literalNull);
        return expression.statement;
    }
}

const Code _bracketOpen = Code('(');
const Code _bracketClose = Code(')');
const Code _orOperator = Code(' || ');

/// A conjunctive combination of one or more fields.
///
class _Combination {

    final List<String> fieldNames;
    final ValidatorFactory _validator;

    _Combination.ofFields(Iterable<String> fieldNames, this._validator)
        : this.fieldNames = List.of(fieldNames)
                                .map((n) => n.trim())
                                .toList();

    /// Produces an expression which formulates the condition of the combination being not set.
    ///
    /// If at least one field in the combination is *NOT* set, the whole combination is *NOT* set.
    ///
    Expression notSetCondition() {
        Expression complexCondition = fieldNames
            .map(_fieldNotSetCondition)
            .reduce((l, r) => _or(l, r));
        return complexCondition;
    }

    Expression _or(Expression left, Expression right) {
        var code = Block.of([_bracketOpen, left.code,  _orOperator, right.code, _bracketClose]);
        return CodeExpression(code);
    }

    Expression _fieldNotSetCondition(String fieldName) {
        var field = _field(fieldName);
        var factory = _validatorFactory(field);
        var fieldAccess = _validator.accessField(field);
        return factory.notSetCondition()(fieldAccess);
    }

    FieldValidatorFactory _validatorFactory(FieldDeclaration field) {
        var factory = FieldValidatorFactory.forField(field, _validator);
        if (factory == null || !factory.supportsRequired()) {
            throw StateError('Field `${_validator.type.fullName}.${field}` cannot be required.');
        }
        return factory;
    }

    FieldDeclaration _field(String protoName) {
        var type = _validator.type;
        FieldDeclaration field = type
                .fields
                .where((t) => t.protoName == protoName)
                .first;
        ArgumentError.checkNotNull(field,
                                   '`${type.fullName}` does not declare field `${protoName}`.');
        return field;
    }
}
