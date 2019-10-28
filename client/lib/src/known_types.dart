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
import 'package:spine_client/types.dart' as standardTypes;

/// The only instance of [KnownTypes].
final theKnownTypes = KnownTypes._instance();

/// All the Protobuf types known to a client application.
///
/// Known types are discovered from `types.dart` files, which are generated by the Proto Dart Gradle
/// plugin.
///
class KnownTypes {

    final Map<String, BuilderInfo> _typeUrlToBuilderInfo = Map();
    final Map<GeneratedMessage, String> _msgToTypeUrl = Map();

    KnownTypes._instance() {
        register(standardTypes.types());
    }

    /// Looks up a [BuilderInfo] by the given type URL.
    ///
    /// Returns `null` if the type is unknown.
    ///
    BuilderInfo findBuilderInfo(String typeUrl) {
        return _typeUrlToBuilderInfo[typeUrl];
    }

    /// Looks up a type URL of the given message.
    ///
    /// Returns `null` if the type is unknown.
    ///
    String typeUrlOf(GeneratedMessage message) {
        var defaultValue = message.createEmptyInstance();
        return _msgToTypeUrl[defaultValue];
    }

    /// Constructs a registry for JSON parsing.
    TypeRegistry registry() {
        return TypeRegistry(_msgToTypeUrl.keys);
    }

    /// Registers the given type provider.
    ///
    /// [types] should be obtained from the `types()` method in the generated `types.dart` file.
    ///
    void register(dynamic types) {
        Map<String, BuilderInfo> typeUrlToBuilderInfo = types.typeUrlToInfo;
        Map<GeneratedMessage, String> msgToTypeUrl = types.defaultToTypeUrl;
        _typeUrlToBuilderInfo.addAll(typeUrlToBuilderInfo);
        _msgToTypeUrl.addAll(msgToTypeUrl);
    }
}
