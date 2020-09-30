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
import 'package:dart_code_gen/google/protobuf/descriptor.pb.dart';
import 'package:dart_code_gen/spine/options.pb.dart';
import 'package:dart_code_gen/src/constraint_violation.dart';
import 'package:dart_code_gen/src/field_validator_factory.dart';
import 'package:dart_code_gen/src/validator_factory.dart';

import 'field_validator_factory.dart';
import 'validator_factory.dart';

const String _validateLib = 'package:spine_client/validate.dart';

/// A [FieldValidatorFactory] for message fields.
///
class MessageValidatorFactory extends SingularFieldValidatorFactory {

    MessageValidatorFactory(ValidatorFactory validatorFactory, FieldDescriptorProto field)
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

    bool _shouldValidate() {
        var options = field.options;
        return options.hasExtension(Options.validate)
            && options.getExtension(Options.validate);
    }

    Rule _createValidateRule() {
        var violationsVar = 'violationsOf_${field.name}';
        return newRule((fieldValue) => _isValidExpression(fieldValue, refer(violationsVar)),
                       (fieldValue) => _produceViolation(refer(violationsVar)),
          preparation: (fieldValue) => _produceChildViolations(violationsVar, fieldValue));
    }

    Expression _isValidExpression(Expression fieldValue, Expression fieldViolationsList) {
        var notSet = notSetCondition().call(fieldValue);
        var isSet = _brackets(notSet).negate();
        var hasViolations = fieldViolationsList.property('isPresent');
        return isSet.and(hasViolations);
    }

    Expression _brackets(Expression content) {
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
        return violationRef.call([
            literalString('Field must be valid.'),
            literalString(validatorFactory.fullTypeName),
            literalList([field.name])
        ], {
            childConstrainsArg: violationsVar.property('value').property('constraintViolation')
        });
    }
}
