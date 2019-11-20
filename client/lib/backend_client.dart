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

import 'package:http/http.dart' as http;
import 'package:protobuf/protobuf.dart';
import 'package:spine_client/firebase_client.dart';
import 'package:spine_client/src/http_endpoint.dart';
import 'package:spine_client/spine/client/query.pb.dart';
import 'package:spine_client/spine/client/subscription.pb.dart' as pb;
import 'package:spine_client/spine/core/ack.pb.dart';
import 'package:spine_client/spine/core/command.pb.dart';
import 'package:spine_client/spine/web/firebase/query/response.pb.dart';
import 'package:spine_client/spine/web/firebase/subscription/firebase_subscription.pb.dart';
import 'package:spine_client/spine_client.dart';
import 'package:spine_client/src/json.dart';
import 'package:spine_client/src/known_types.dart';

import 'subscription.dart';

/// A client of a Spine-based web server.
///
/// Communicates with the backend via the Spine Firebase-web protocol.
///
/// For read operations, the client sends a request to the Spine-based server, receives a path to
/// a node in Firebase Realtime Database in response, and fetches the data under that node.
///
class BackendClient {

    /// A period which is used to send a "subscription keep-up" request for all active
    /// subscriptions.
    ///
    /// The Spine server cancels the stale subscriptions after some period of time. To prevent this
    /// from happening to the active subscriptions of this client, we need to periodically send a
    /// "keep-up" request to the corresponding endpoint.
    ///
    static final Duration subscriptionKeepUpPeriod = new Duration(minutes: 2);

    final HttpEndpoint _endpoint;
    final FirebaseClient _database;
    final List<Subscription> _activeSubscriptions = [];

    /// Creates a new instance of `BackendClient`.
    ///
    /// The client connects to the Spine-based server at the given [_endpoint] and reads query
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
    BackendClient(String serverUrl, this._database, {List<dynamic> typeRegistries = const []})
            : _endpoint = HttpEndpoint(serverUrl) {
        for (var registry in typeRegistries) {
            theKnownTypes.register(registry);
        }
        Timer.periodic(subscriptionKeepUpPeriod, (timer) => _keepUpSubscriptions());
    }

    /// Posts a given [Command] to the server.
    Future<Ack> post(Command command) {
        var result = _endpoint
            .postMessage('command', command)
            .then(_parseAck);
        return result;
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
        var targetTypeUrl = query.target.type;
        var builder = theKnownTypes.findBuilderInfo(targetTypeUrl);
        if (builder == null) {
            throw ArgumentError.value(query, 'query', 'Target type `$targetTypeUrl` is unknown.');
        }
        var qr = await _endpoint
            .postMessage('query', query)
            .then(_parseQueryResponse);
        yield* _database
            .get(qr.path)
            .take(qr.count.toInt())
            .map((json) => parseIntoNewInstance(builder, json));
    }

    /// Subscribes to the changes of entities described by the given [topic].
    ///
    /// Sends a subscription request to the server and receives a path to the Firebase Realtime
    /// Database node where the entity changes are reflected.
    ///
    /// Based on the given location in the database, builds a [Subscription] which allows to listen
    /// to the entity or event changes in the convenient format of [Stream]s.
    ///
    /// Throws an exception if the query is invalid or if any kind of network or server error
    /// occurs.
    ///
    Future<Subscription<T>> subscribeTo<T extends GeneratedMessage>(pb.Topic topic) async {
        var targetTypeUrl = topic.target.type;
        var builder = theKnownTypes.findBuilderInfo(targetTypeUrl);
        if (builder == null) {
            throw ArgumentError.value(topic, 'topic', 'Target type `$targetTypeUrl` is unknown.');
        }
        var response = await _endpoint
            .postMessage('subscription/create', topic)
            .then(_parseFirebaseSubscription);

        Subscription<T> subscription = Subscription.of(response, _database);
        _activeSubscriptions.add(subscription);
        return subscription;
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

    FirebaseSubscription _parseFirebaseSubscription(http.Response response) {
        var firebaseSubscription = FirebaseSubscription();
        _parseInto(firebaseSubscription, response);
        return firebaseSubscription;
    }

    void _parseInto(GeneratedMessage message, http.Response response) {
        var json = response.body;
        parseInto(message, json);
    }

    void _keepUpSubscriptions() {
        _activeSubscriptions.forEach(_keepUpSubscription);
    }

    void _keepUpSubscription(Subscription subscription) {
        var subscriptionMessage = subscription.subscription;
        if (subscription.closed) {
            _cancel(subscriptionMessage);
            _activeSubscriptions.remove(subscription);
        } else {
            _keepUp(subscriptionMessage);
        }
    }

    void _keepUp(pb.Subscription subscription) {
        _endpoint.postMessage('subscription/keep-up', subscription);
    }

    void _cancel(pb.Subscription subscription) {
        _endpoint.postMessage('subscription/cancel', subscription);
    }
}
