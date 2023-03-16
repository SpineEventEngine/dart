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

import 'dart:convert';

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/http_client.dart';
import 'package:spine_client/json.dart';

const _json = JsonCodec();
const _reversedJsonContentType = {'Content-Type': 'application/reversed-json'};

/// A translator which analyzes the URI of the request,
/// and if it matches the specified path fragment,
/// sends and receives Proto messages as JSON strings,
/// in which their characters are in reverse order.
///
/// Otherwise, returns the default values as specified by [HttpTranslator].
///
class ReversingHttpTranslator extends HttpTranslator {

    final TypeRegistry typeRegistry;
    final String matchingPath;

    ReversingHttpTranslator(this.typeRegistry, this.matchingPath);

    /// For the matching path, transforms the provided [message]
    /// into a JSON string in which the characters are in reversed order.
    ///
    @override
    String body(Uri uri, GeneratedMessage message) {
        if(!_matchesPath(uri)) {
            return super.body(uri, message);
        }
        var jsonObject = message.toProto3Json(typeRegistry: typeRegistry);
        var json = _json.encode(jsonObject);
        String reversed = _reverse(json);
        return reversed;
    }

    bool _matchesPath(Uri uri) => uri.path.contains(matchingPath);

    /// Returns `{'Content-Type': 'application/reversed-json'}` for the matching path.
    ///
    @override
    Map<String, String> headers(Uri uri) {
        if(!_matchesPath(uri)) {
            return super.headers(uri);
        }
        return _reversedJsonContentType;
    }

    /// For the matching path, parses the provided response body
    /// considering it as a JSON string with characters in reverse order,
    /// and transforms it to a Proto message of type [T].
    ///
    /// Parameters:
    /// - [uri] the URI of the resource, from which the HTTP response is obtained
    /// - [responseBody] body of a successful HTTP response
    /// - [destination] an instance of Proto message into which the translated data is to be merged
    ///
    @override
    T translate<T extends GeneratedMessage>(Uri uri, String responseBody, T destination) {
        if(!_matchesPath(uri)) {
            return super.translate(uri, responseBody, destination);
        }
        var reversed = _reverse(responseBody);
        parseInto(destination, reversed);
        return destination;
    }

    static String _reverse(String value) {
      var reversed = value.split('').reversed.join('');
      return reversed;
    }
}