/*
 * Copyright 2020, TeamDev. All rights reserved.
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

import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/src/known_types.dart';
import 'package:spine_client/src/validate.dart';

abstract class Message<T extends Message<T, M>, M extends GeneratedMessage> {

    M getAsMutable() {
        return null;
    }

    String getTypeUrl() {
        return theKnownTypes.typeUrlOf(getAsMutable());
    }

    Uint8List writeToBuffer() => getAsMutable().writeToBuffer();
}

abstract class ValidatingBuilder<T extends Message<T, M>, M extends GeneratedMessage> {

    M mutableMessage() => build().getAsMutable();

    void validate() {
        var msg = mutableMessage();
        checkValid(msg);
    }

    T build();

    T vBuild() {
        validate();
        return build();
    }
}
