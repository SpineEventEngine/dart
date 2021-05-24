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

import '../dart_code_gen.dart';
import '../google/protobuf/descriptor.pb.dart';
import '../spine/options.pb.dart';
import 'constraint_violation.dart';
import 'field_validator_factory.dart';
import 'imports.dart';
import 'required_field_validation_factory.dart';
import 'type.dart';

const _violations = 'violations';
const _msg = 'msg';

/// Factory of message validation code for a Protobuf type.
///
/// For a given Protobuf message type, generates a lambda which accepts a single message and creates
/// a `spine.validate.ValidationError`. If the given message is valid, the lambda returns `null`.
/// Otherwise, it returns all `ConstraintViolation`s for the message as a single error.
///
/// Note that the type of the input message is not checked. Users should wrap calls to validators
/// in type-aware abstractions instead of referring to them directly.
///
class ValidatorFactory {

    final FileDescriptorProto file;
    final MessageType type;
    final Properties properties;

    ValidatorFactory(this.file, this.type, this.properties);

    String get fullTypeName => type.fullName;

    ViolationConsumer get report =>
            (Expression violation) => _violationList.property('add').call([violation]);

    String get _fileName => type.dartFilePath;

    Reference get _violationList => refer(_violations);

    Expression get _emptyValidationError =>
        refer('ValidationError', validationErrorImport(properties.standardPackage))
            .newInstance([]);

    /// Creates a validator expression.
    ///
    Expression createValidator() {
        var param = Parameter((b) => b
            ..type = refer('GeneratedMessage', protobufImport)
            ..name = _msg);
        try {
            return Method((b) => b
                ..requiredParameters.add(param)
                ..body = _collectStatements()
            ).closure;
        } catch (e) {
            throw StateError('Cannot generate validation code for `$fullTypeName`. '
                             '${e.toString()}');
        }
    }

    Code _collectStatements() {
        var statements = <Code>[];
        statements.add(_newViolationList().statement);
        statements.add(_createRequiredFieldValidator());
        statements.add(_createFieldValidators());
        var error = 'error';
        var errorRef = refer(error);
        statements.add(_newValidationError(error).statement);
        statements.add(_fillInViolations(errorRef).statement);
        statements.add(errorRef.returned.statement);
        return Block.of(statements);
    }

    Code _createRequiredFieldValidator() {
        var options = type.descriptor.options;
        var option = Options.requiredField;
        if (options.hasExtension(option)) {
            var fields = options.getExtension(option);
            var factory = RequiredFieldValidatorFactory.forExpression(fields, this, report);
            var validator = factory.generate();
            return validator;
        } else {
            return Block.of([]);
        }
    }

    Code _createFieldValidators() {
        var validations = <Code>[];
        for (var field in type.fields) {
            var validator = _createFieldValidator(field);
            if (validator != null) {
                validations.add(validator);
            }
        }
        return Block.of(validations);
    }

    Expression _fillInViolations(Reference errorRef) {
        return errorRef.property('constraintViolation')
            .property('addAll')
            .call([refer(_violations)]);
    }

    Expression _newViolationList() {
        return literalList([], violationTypeRef(properties.standardPackage))
            .assignVar(_violations);
    }

    Expression _newValidationError(String error) {
        return _emptyValidationError.assignVar(error);
    }

    /// Generates validation code for a given field.
    ///
    /// For this, the message is cast to the expected type and the field value is obtained.
    ///
    /// See [FieldValidatorFactory] for more on field validation.
    ///
    Code _createFieldValidator(FieldDeclaration field) {
        var factory = FieldValidatorFactory.forField(field, this);
        var fieldValue = accessField(field);
        return factory.createFieldValidator(fieldValue);
    }

    Expression accessField(FieldDeclaration field) => _typedMessage.property(field.escapedDartName);

    Expression get _typedMessage =>
        refer(_msg).asA(_typeRef(properties.importPrefix));

    Reference _typeRef(String prefix) =>
        refer(type.dartClassName, prefix.isNotEmpty ? '$prefix/$_fileName' : _fileName);
}

/// A functional interface which transforms an expression of [constraintViolation] into an
/// expression which reports the given violation.
///
/// The violations may be accumulated this way over many fields of a validated message.
///
typedef Expression ViolationConsumer(Expression constraintViolation);
