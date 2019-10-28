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
import 'package:spine_client/google/protobuf/any.pb.dart';
import 'package:spine_client/src/known_types.dart';

/// Separates the type URL prefix from the type name.
const _prefixSeparator = '/';

/// Unpacks the given [any] into a message.
///
/// The message type is inferred from the [Any.typeUrl] via the [KnownTypes]. If the type is
/// unknown, an error is thrown.
///
GeneratedMessage unpack(Any any) {
    var typeUrl = any.typeUrl;
    var builder = theKnownTypes.findBuilderInfo(typeUrl);
    if (builder == null) {
        throw ArgumentError('Cannot unpack unknown type `$typeUrl`.');
    }
    var emptyInstance = builder.createEmptyInstance();
    return any.unpackInto(emptyInstance);
}

/// Packs the given [message] into an [Any].
///
/// The type URL prefix is looked up in the [KnownTypes]. If the type is unknown, an error is
/// thrown.
///
Any pack(GeneratedMessage message) {
    return Any.pack(message, typeUrlPrefix: _typeUrlPrefix(message));
}

String _typeUrlPrefix(GeneratedMessage message) {
    var typeUrl = theKnownTypes.typeUrlOf(message);
    if (typeUrl == null) {
        throw ArgumentError('Cannot pack message of unknown type `${message.runtimeType}`.');
    }
    var typeName = message.info_.qualifiedMessageName;
    var matchingType = typeUrl.endsWith(typeName);
    if (!matchingType) {
        throw StateError('Type URL $typeUrl does not match type `${message.runtimeType}`. ' +
                         'Try rebuilding generated type registry.');
    }
    return typeUrl.substring(0, typeUrl.length - typeName.length - _prefixSeparator.length);
}
