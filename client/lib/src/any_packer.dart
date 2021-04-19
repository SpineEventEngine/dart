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

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:spine_client/google/protobuf/any.pb.dart';
import 'package:spine_client/google/protobuf/type.pb.dart';
import 'package:spine_client/google/protobuf/wrappers.pb.dart';
import 'package:spine_client/src/known_types.dart';
import 'package:spine_client/unknown_type.dart';

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
        throw UnknownTypeError(typeUrl: typeUrl);
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

/// Packs the given [id] into an [Any].
///
/// An `int` ID is packed as an `Int32Value`. A `fixnum.Int64` ID is packed as an `Int64Value`.
/// A `Sting` ID is packed as a `StringValue`. A message is packed as itself. Other types of IDs
/// are not supported and would cause an `ArgumentError`.
///
Any packId(Object rawId) {
    ArgumentError.checkNotNull(rawId);
    if (rawId is GeneratedMessage || rawId is String || rawId is int || rawId is Int64) {
        return packObject(rawId);
    } else {
        throw ArgumentError('Instance of type ${rawId.runtimeType} cannot be an ID.');
    }
}

/// Packs the given [value] into an [Any].
///
/// Supported types are:
///  - `int`, packed as an `Int32Value`.
///  - `fixnum.Int64`, packed as an `Int64Value`.
///  - `Sting`, packed as a `StringValue`.
///  - `bool`, packed as a `BoolValue`.
///  - `double`, packed as a `DoubleValue`.
///  - `ProtobufEnum`, packed as a `EnumValue`.
///  - `GeneratedMessage`, packed as itself.
///
/// Other types are not supported and would cause an `ArgumentError`.
///
Any packObject(Object value) {
    ArgumentError.checkNotNull(value);
    if (value is Any) {
        return value;
    } else if (value is GeneratedMessage) {
        return pack(value);
    } else if (value is ProtobufEnum) {
        var enumValue = EnumValue()
            ..name = value.name
            ..number = value.value;
        return pack(enumValue);
    } else  if (value is String) {
        return pack(StringValue()..value = value);
    } else if (value is int) {
        return pack(Int32Value()..value = value);
    } else if (value is Int64) {
        return pack(Int64Value()..value = value);
    } else if (value is double) {
        return pack(DoubleValue()..value = value);
    } else if (value is bool) {
        return pack(BoolValue()..value = value);
    } else if (value is List && (value.isEmpty || value[0] is int)) {
        return pack(BytesValue()..value = value);
    } else {
        throw ArgumentError('Instance of type ${value.runtimeType} cannot be '
                            'packed into a `google.protobuf.Any`.');
    }
}

String _typeUrlPrefix(GeneratedMessage message) {
    var typeUrl = theKnownTypes.typeUrlOf(message);
    var typeName = message.info_.qualifiedMessageName;
    var matchingType = typeUrl.endsWith(typeName);
    if (!matchingType) {
        throw StateError('Type URL $typeUrl does not match type `${message.runtimeType}`. ' +
                         'Try rebuilding generated type registry.');
    }
    return typeUrl.substring(0, typeUrl.length - typeName.length - _prefixSeparator.length);
}
