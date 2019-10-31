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

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:protobuf/protobuf.dart';
import 'package:spine_client/firebase_client.dart';
import 'package:spine_client/spine/client/query.pb.dart';
import 'package:spine_client/spine/core/ack.pb.dart';
import 'package:spine_client/spine/core/command.pb.dart';
import 'package:spine_client/spine/web/firebase/query/response.pb.dart';
import 'package:spine_client/src/known_types.dart';
import 'package:spine_client/src/url.dart';

const _base64 = Base64Codec();
const _json = JsonCodec();
const _contentType = { 'Content-Type': 'application/x-protobuf'};

/// A client of a Spine-based web server.
///
/// Communicates with the backend via the Spine Firebase-web protocol.
///
/// For read operations, the client sends a request to the Spine-based server, receives a path to
/// a node in Firebase Realtime Database in response, and fetches the data under that node.
///
class BackendClient {

    final String _baseUrl;
    final FirebaseClient _database;

    /// Creates a new instance of `BackendClient`.
    ///
    /// The client connects to the Spine-based server by the given [_baseUrl] and reads query
    /// responses from the given Firebase [_database].
    ///
    /// The client may accept [typeRegistries] defined by the client modules.
    ///
    /// Example:
    /// ```dart
    ///
    /// import 'package:example_dependency/types.dart' as dependencyTypes;
    /// import 'types.dart' as myTypes;
    ///
    /// var firebase = RestClient(fb.FirebaseClient.anonymous(),
    ///                           'https://example-org-42.firebaseio.com');
    /// var client = BackendClient('https://example.org',
    ///                            firebase,
    ///                            typeRegistries: [myTypes.types(), dependencyTypes.types()]);
    /// ```
    ///
    BackendClient(this._baseUrl, this._database, {List<dynamic> typeRegistries = const []}) {
        for (var registry in typeRegistries) {
            theKnownTypes.register(registry);
        }
    }

    /// Posts a given [Command] to the server.
    Future<Ack> post(Command command) {
        var body = command.writeToBuffer();
        return http
            .post(Url.from(_baseUrl, 'command').stringUrl,
                  body: _base64.encode(body),
                  headers: _contentType)
            .then(_parseAck);
    }

    /// Obtains entities matching the given query from the server.
    ///
    /// Sends a [Query] to the server and receives a path to a node in Firebase Realtime Database.
    /// The node's children represent the entities matching the query.
    ///
    /// Throws an exception if the query is invalid or if any kind of network or server error
    /// occurs.
    ///
    Stream<T> fetch<T extends GeneratedMessage>(Query query) async* {
        var body = query.writeToBuffer();
        var targetTypeUrl = query.target.type;
        var builder = theKnownTypes.findBuilderInfo(targetTypeUrl);
        if (builder == null) {
            throw ArgumentError.value(query, 'query', 'Target type `$targetTypeUrl` is unknown.');
        }
        var qr = await http.post(Url.from(_baseUrl, 'query').stringUrl,
                                 body: _base64.encode(body),
                                 headers: _contentType)
            .then(_parseQueryResponse);
        yield* _database
            .get(qr.path)
            .take(qr.count.toInt())
            .map((json) => _copyAndParse(builder, json));
    }

    T _copyAndParse<T extends GeneratedMessage>(BuilderInfo builderInfo, String json) {
        var msg = builderInfo.createEmptyInstance();
        _parseJson(msg, json);
        return msg;
    }

    Ack _parseAck(http.Response response) {
        var ack = Ack();
        _parseInto(ack, response);
        return ack;
    }

    FirebaseQueryResponse _parseQueryResponse(http.Response response) {
        var queryResponse = FirebaseQueryResponse();
        _parseInto(queryResponse, response);
        return queryResponse;
    }

    void _parseInto(GeneratedMessage message, http.Response response) {
        var json = response.body;
        _parseJson(message, json);
    }

    void _parseJson(GeneratedMessage message, String json) {
        var jsonMap = _json.decode(json);
        message.mergeFromProto3Json(jsonMap,
                                    ignoreUnknownFields: true,
                                    typeRegistry: theKnownTypes.registry());
    }
}
