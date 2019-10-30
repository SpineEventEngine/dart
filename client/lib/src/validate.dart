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

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/spine/validate/validation_error.pb.dart';
import 'package:spine_client/src/known_types.dart';
import 'package:sprintf/sprintf.dart';

/// Validates the given message according to the constrains defined in Protobuf.
///
/// Returns a [ValidationError] if the [message] is invalid, otherwise returns `null`.
///
ValidationError validate(GeneratedMessage message) {
    ArgumentError.checkNotNull(message, 'message');
    var validate = theKnownTypes.validatorFor(message);
    if (validate == null) {
        return null;
    }
    var error = validate(message);
    if (error == null || error.constraintViolation.isEmpty) {
        return null;
    }
    return error;
}

/// Validates the given message according to the constrains defined in Protobuf and throws
/// an [InvalidMessageError] if the [message] is invalid.
void checkValid(GeneratedMessage message) {
    var error = validate(message);
    if (error != null) {
        throw InvalidMessageError._(error);
    }
}

/// Checks if the given [message] is in the default state.
bool isDefault(GeneratedMessage message) =>
    message == message.createEmptyInstance();

/// An error which occurs when validating an invalid message.
class InvalidMessageError extends Error {

    /// This error as a [ValidationError].
    final ValidationError asValidationError;

    /// The constraint violations which caused the error.
    List<ConstraintViolation> get violations => asValidationError.constraintViolation;

    InvalidMessageError._(this.asValidationError) {
        asValidationError.freeze();
    }

    @override
    String toString() =>
        violations.map(_violationText)
                  .join('\n');

    String _violationText(ConstraintViolation violation) {
        var type = violation.typeName;
        var fieldPath = violation
            .fieldPath
            .fieldName
            .join('.');
        var result = StringBuffer();
        _writePrefix(type, result);
        _writePrefix(fieldPath, result);
        var format = violation.msgFormat;
        var params = violation.param;
        var message = params.isEmpty
                    ? format
                    : sprintf(format, violation.param);
        result.write(message);
        return result.toString();
    }

    void _writePrefix(String prefix, StringBuffer target) {
        if (prefix.isNotEmpty) {
            target.write('At `$prefix`: ');
        }
    }
}
