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

/// An error emitted when an unknown Protobuf type is encountered.
///
/// Typically, this error means that the type is not registered in the known types registry.
/// To fix this, a user should pass `protoTypes.types()` to a constructor of `Clients`, where
/// `protoTypes` is an import prefix for the local `types.dart` file. See the documentation of
/// `Clients` for more info.
///
class UnknownTypeError extends Error {

    final String _message;

    /// Creates a new instance of `UnknownTypeError`.
    ///
    /// Exactly one parameter should be passed to this constructor, a [typeUrl] or a [runtimeType].
    /// If none is passed, an `ArgumentError` is thrown.
    ///
    UnknownTypeError({String? typeUrl, Type? runtimeType}) :
        _message = _composeMessage(typeUrl, runtimeType);

    static String _composeMessage(String? typeUrl, Type? runtimeType) {
        String type;
        if (typeUrl != null) {
            type = typeUrl;
        } else if (runtimeType != null) {
            type = runtimeType.toString();
        } else {
            throw ArgumentError('Cannot create an `UnknownTypeError` without a type.');
        }
        return '${UnknownTypeError}: `${type}` is unknown. Make sure to pass the generated type '
               'registry to the constructor of `Clients`.';
    }

    @override
    String toString() => _message;
}
