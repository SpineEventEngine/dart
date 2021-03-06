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

import 'package:http/http.dart' as http;
import 'package:protobuf/protobuf.dart';
import 'package:spine_client/firebase_client.dart';
import 'package:spine_client/spine/client/query.pb.dart';
import 'package:spine_client/spine/web/firebase/query/response.pb.dart';
import 'package:spine_client/src/json.dart';
import 'package:spine_client/src/known_types.dart';

import 'any_packer.dart';

/// A strategy of processing HTTP responses from the query endpoint.
abstract class QueryResponseProcessor {

    Stream<T> process<T extends GeneratedMessage>(Future<http.Response> httpResponse, Query query);
}

/// Parses the HTTP response as a Firebase database reference and reads the query response from
/// by that reference.
class FirebaseResponseProcessor implements QueryResponseProcessor {

    final FirebaseClient _database;

    FirebaseResponseProcessor(this._database) {
        ArgumentError.checkNotNull(_database, 'FirebaseClient');
    }

    @override
    Stream<T> process<T extends GeneratedMessage>(Future<http.Response> httpResponse, Query query) {
        var targetTypeUrl = query.target.type;
        var builder = theKnownTypes.findBuilderInfo(targetTypeUrl);
        if (builder == null) {
            throw ArgumentError.value(query, 'query', 'Target type `$targetTypeUrl` is unknown.');
        }
        return httpResponse.then(_parse)
                           .asStream()
                           .asyncExpand((response) => _database.get(response.path)
                                                               .take(response.count.toInt()))
                           .map((json) => parseIntoNewInstance(builder, json));
  }

    FirebaseQueryResponse _parse(http.Response response) {
        var queryResponse = FirebaseQueryResponse();
        _parseInto(queryResponse, response);
        return queryResponse;
    }
}

/// Parses the HTTP response as a [QueryResponse].
class DirectResponseProcessor extends QueryResponseProcessor {

    @override
    Stream<T> process<T extends GeneratedMessage>(Future<http.Response> httpResponse, Query query) {
        var response = httpResponse.then(_parse);
        var entities = response.asStream()
                               .expand((r) => r.message)
                               .map((entity) => unpack(entity.state) as T);
        return entities;
    }

    QueryResponse _parse(http.Response response) {
        var queryResponse = QueryResponse();
        _parseInto(queryResponse, response);
        return queryResponse;
    }
}

void _parseInto(GeneratedMessage message, http.Response response) {
    var json = response.body;
    parseInto(message, json);
}
