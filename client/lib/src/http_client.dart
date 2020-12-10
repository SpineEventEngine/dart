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

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:protobuf/protobuf.dart';
import 'package:spine_client/src/url.dart';

const _base64 = Base64Codec();
const _protobufContentType = {'Content-Type': 'application/x-protobuf'};

/// An HTTP client for connecting to the backend.
///
class HttpClient {

    final String _baseUrl;
    final OnNetworkError _onNetworkError;

    HttpClient(this._baseUrl, this._onNetworkError) {
        ArgumentError.checkNotNull(_baseUrl, 'base URL');
    }

    /// Sends an HTTP POST request at the given path with the given message as request body.
    ///
    /// The given [path] will be concatenated with the [_baseUrl].
    ///
    Future<http.Response> postMessage(String path, GeneratedMessage message) {
        var bytes = message.writeToBuffer();
        var url = Url.from(_baseUrl, path).stringUrl;
        var response = http.post(url, body: _base64.encode(bytes), headers: _protobufContentType);
        if (_onNetworkError != null) {
            response.catchError(_onNetworkError);
        }
        return response;
    }
}

typedef OnNetworkError = FutureOr<http.Response> Function(dynamic, [StackTrace]);
