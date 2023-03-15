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

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:protobuf/protobuf.dart';
import 'package:spine_client/src/url.dart';

import 'client.dart';
import 'json.dart';

const _base64 = Base64Codec();
const _protobufContentType = {'Content-Type': 'application/x-protobuf'};

/// An HTTP client for connecting to the backend.
///
class HttpClient {

    final String _baseUrl;
    final HttpTranslator _translator;

    HttpClient(String baseUrl) : this.withTranslator(baseUrl, HttpTranslator());

    HttpClient.withTranslator(String baseUrl, HttpTranslator translator)
        : this._translator = ArgumentError.checkNotNull(translator, 'HTTP translator'),
          this._baseUrl = ArgumentError.checkNotNull(baseUrl, 'base URL');


    /// Sends an HTTP POST request at the given path with the given message as request body.
    ///
    /// The given [path] will be concatenated with the [_baseUrl].
    ///
    Future<http.Response> postMessage(UrlPath path, GeneratedMessage message) {
        String preparedBody = _translator.body(message);
        var url = Url.from(_baseUrl, path).asUri;
        var response = http.post(url, body: preparedBody, headers: _translator.headers());
        return response;
    }

    Future<T> postAndTranslate<T extends GeneratedMessage>
        (UrlPath path, GeneratedMessage msg, T destination) {
        var response = postMessage(path, msg);
        return response.then((r) => _translator.translate(r.body, destination));
    }
}

/// Serves to configure HTTP requests for posting, and translates the corresponding responses.
///
/// This is an extension point for users of [Client] API. Custom [HttpTranslator]
/// implementation, once set, may serve as an adapter to the circumstances,
/// under which the server-side of the application is running.
///
class HttpTranslator {

    /// Transforms the given [message] into [String] which is used as HTTP POST body
    /// by [postMessage].
    ///
    /// By default, transforms the message into bytes, and encodes it with Base64.
    ///
    String body(GeneratedMessage message) {
        var bytes = message.writeToBuffer();
        var result = _base64.encode(bytes);
        return result;
    }

    /// Returns HTTP request headers to use in [postMessage].
    ///
    /// By default, returns `{'Content-Type': 'application/x-protobuf'}`.
    ///
    Map<String, String> headers() => _protobufContentType;

    /// Translates the HTTP response body into an object of type [T].
    ///
    /// By default, parses the response body as JSON.
    ///
    /// Parameters:
    /// - [responseBody] body of a successful HTTP response
    /// - [destination] an instance of Proto message into which the translated data is to be merged
    ///
    T translate<T extends GeneratedMessage>(String responseBody, T destination) {
        parseInto(destination, responseBody);
        return destination;
    }
}
