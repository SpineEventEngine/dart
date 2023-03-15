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

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/firebase_client.dart';
import 'package:spine_client/spine/client/query.pb.dart';
import 'package:spine_client/spine/web/firebase/query/response.pb.dart';
import 'package:spine_client/json.dart';
import 'package:spine_client/known_types.dart';

import 'any_packer.dart';
import '../http_client.dart';

/// A strategy of executing [Query] instances through query endpoint via HTTP.
abstract class QueryProcessor {

    Stream<T> execute<T extends GeneratedMessage>(Query query, String endpoint);
}

/// Posts [Query] message to the corresponding endpoint via HTTP,
/// parses the HTTP response as a Firebase database reference,
/// and reads the query response from Firebase by that reference.
///
class FirebaseQueryProcessor implements QueryProcessor {

    final FirebaseClient _database;
    final HttpClient _httpClient;

    FirebaseQueryProcessor(this._database, this._httpClient) {
        ArgumentError.checkNotNull(_database, 'FirebaseClient');
        ArgumentError.checkNotNull(_httpClient, 'HttpClient');
    }

    @override
    Stream<T> execute<T extends GeneratedMessage>(Query query, String endpoint) {
        var targetTypeUrl = query.target.type;
        var builder = theKnownTypes.findBuilderInfo(targetTypeUrl);
        if (builder == null) {
            throw ArgumentError.value(query, 'query', 'Target type `$targetTypeUrl` is unknown.');
        }

        return _httpClient.postAndTranslate(endpoint, query, FirebaseQueryResponse())
            .asStream()
            .asyncExpand((response) => _database.get(response.path).take(response.count.toInt()))
            .map((json) => parseIntoNewInstance(builder, json));
    }
}

/// Posts [Query] message to the corresponding endpoint via HTTP,
/// and parses the HTTP response as a [QueryResponse].
///
class DirectQueryProcessor extends QueryProcessor {

    final HttpClient _httpClient;

    DirectQueryProcessor(this._httpClient) {
        ArgumentError.checkNotNull(_httpClient, 'HttpClient');
    }

    @override
    Stream<T> execute<T extends GeneratedMessage>(Query query, String endpoint) {
        var entities = _httpClient.postAndTranslate(endpoint, query, QueryResponse())
            .asStream()
            .expand((r) => r.message)
            .map((entity) => unpack(entity.state) as T);
        return entities;
    }
}
