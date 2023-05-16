/*
 * Copyright 2023, TeamDev. All rights reserved.
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
import 'package:dart_code_gen/spine/options.pb.dart';
import 'package:dart_code_gen/src/constraint_violation.dart';
import 'package:dart_code_gen/src/field_validator_factory.dart';
import 'package:dart_code_gen/src/type.dart';
import 'package:dart_code_gen/src/validator_factory.dart';

import 'field_validator_factory.dart';
import 'validator_factory.dart';

const String _validateLib = 'package:spine_client/validate.dart';

/// A [FieldValidatorFactory] for message fields.
///
class MessageValidatorFactory extends SingularFieldValidatorFactory {

    MessageValidatorFactory(ValidatorFactory validatorFactory, FieldDeclaration field)
        : super(validatorFactory, field);

    @override
    Iterable<Rule> rules() {
        var rules = <Rule>[];
        if (isRequired()) {
            rules.add(createRequiredRule());
        }
        if (_shouldValidate()) {
            rules.add(_createValidateRule());
        }
        return rules;
    }

    @override
    LazyCondition notSetCondition() =>
            (v) => v.property('createEmptyInstance').call([]).equalTo(v);

    /// Checks if the field should be validated according to the `(validate)` option.
    bool _shouldValidate() => field.findOption(Options.validate).orElse(false);

    /// Constructs a [Rule] for validating the field message value.
    Rule _createValidateRule() {
        var violationsVar = 'violationsOf_${field.dartName}';
        return newRule((fieldValue) => _isValidExpression(fieldValue, refer(violationsVar)),
                       (fieldValue) => _produceViolation(refer(violationsVar)),
          preparation: (fieldValue) => _produceChildViolations(violationsVar, fieldValue));
    }

    Expression _isValidExpression(Expression fieldValue, Expression fieldViolationsList) {
        var notSet = notSetCondition().call(fieldValue);
        var isSet = _parentheses(notSet).negate();
        var hasViolations = fieldViolationsList.property('isPresent');
        return isSet.and(hasViolations);
    }

    /// Creates an expression which inboxes the given [content] into parentheses.
    Expression _parentheses(Expression content) {
        return CodeExpression(Block.of([
            const Code('('),
            content.code,
            const Code(')')
        ]));
    }

    Code _produceChildViolations(String targetViolationsVar, Expression fieldValue) {
        var violationsCall = refer('validate', _validateLib).call([fieldValue]);
        return violationsCall.assignVar(targetViolationsVar).statement;
    }

    Expression _produceViolation(Expression violationsVar) {
        var message = field.findOption(Options.ifInvalid)
                           .map((val) => val.msgFormat)
                           .orElse('The message must have valid properties.');
        return violationRef.call([
            literalString(message),
            literalString(validatorFactory.fullTypeName),
            literalList([field.protoName])
        ], {
            childConstraintsArg: violationsVar.property('value').property('constraintViolation')
        });
    }
}
