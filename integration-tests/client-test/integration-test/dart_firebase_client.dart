/*
 * Copyright 2022, TeamDev. All rights reserved.
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

import 'package:firebase_dart/firebase_dart.dart' as fb;
import 'package:spine_client/firebase_client.dart';

/// An implementation of [FirebaseClient] that uses native firebase implementation.
///
class DartFirebaseClient implements FirebaseClient {

    final fb.FirebaseDatabase _db;

    DartFirebaseClient(this._db);

    @override
    Stream<String> get(String path) {
        return childAdded(path);
    }

    @override
    Stream<String> childAdded(String path) {
        return _db
            .reference()
            .child(path)
            .onChildAdded
            .map(_toJsonString);
    }

    @override
    Stream<String> childChanged(String path) {
        return _db
            .reference()
            .child(path)
            .onChildChanged
            .map(_toJsonString);
    }

    @override
    Stream<String> childRemoved(String path) {
        return _db
            .reference()
            .child(path)
            .onChildRemoved
            .map(_toJsonString);
    }

    String _toJsonString(fb.Event event) {
        return event.snapshot.value.toString();
    }
}
