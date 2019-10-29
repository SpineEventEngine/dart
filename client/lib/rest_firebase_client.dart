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

import 'package:firebase/firebase_io.dart' as fb;
import 'package:spine_client/firebase_client.dart';
import 'package:spine_client/src/url.dart';

/// A [FirebaseClient] based on the Firebase REST API.
///
/// This implementation does not have platform limitations.
///
/// See `WebFirebaseClient` for a web-specific implementation.
///
class RestClient implements FirebaseClient {

    final fb.FirebaseClient _client;
    final String _databaseUrl;

    /// Creates a new [RestClient] which connects to the database on the given [_databaseUrl]
    /// with the given REST API [_client].
    RestClient(this._client, this._databaseUrl);

    @override
    Stream<String> get(String path) async* {
        var root = await _client.get(Url.from(_databaseUrl, '${path}.json').stringUrl);
        for (var element in root.values) {
            yield element.toString();
        }
    }
}
