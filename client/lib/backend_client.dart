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
import 'package:spine_client/spine/client/query.pb.dart';
import 'package:spine_client/spine/client/subscription.pb.dart' as pb;
import 'package:spine_client/spine/core/ack.pb.dart';
import 'package:spine_client/spine/core/command.pb.dart';
import 'package:spine_client/spine/web/firebase/subscription/firebase_subscription.pb.dart';
import 'package:spine_client/spine_client.dart';
import 'package:spine_client/src/http_client.dart';
import 'package:spine_client/src/known_types.dart';
import 'package:spine_client/src/query_processor.dart';

import 'subscription.dart';

/// A client of a Spine-based web server.
///
/// Posts commands, sends queries, and manages subscriptions.
///
/// There are two modes for querying the data from backend:
///   1. Firebase mode (default) — the Firebase Database is used to deliver query
///      and subscription results. The client sends a request to the backend, receives a path to
///      a node in Firebase Realtime Database in response, and fetches the data under that node.
///   2. Direct mode — the Firebase Database is only used for subscription updates, while
///      query results are delivered directly in HTTP responses. In this mode, if there is no need
///      to use subscriptions, the firebase client is not required.
///
class BackendClient {

    static const Duration _defaultSubscriptionKeepUpPeriod = Duration(minutes: 2);

    final HttpClient _httpClient;
    final FirebaseClient _database;
    final List<StateSubscription> _activeSubscriptions = [];

    /// Endpoints to which this client connects.
    Endpoints _endpoints;

    /// A period with which the "subscription keep-up" request is sent for all active
    /// subscriptions.
    ///
    /// The Spine server cancels stale subscriptions after some period of time. To prevent this
    /// from happening we need to periodically send a "keep-up" request to the corresponding
    /// endpoint.
    ///
    /// This property allows to configure the period with which the request is sent. It should have
    /// a value at least no less than the subscription life span configured by the server.
    ///
    /// The default value is 2 minutes.
    ///
    final Duration subscriptionKeepUpPeriod;

    final QueryResponseProcessor _queryProcessor;

    /// Creates a new instance of `BackendClient`.
    ///
    /// The client connects to the Spine-based server at the given [_httpClient].
    ///
    /// To choose a query mode, specify the [queryMode] argument The default value
    /// is `QueryMode.FIREBASE`.
    ///
    /// The client may accept [typeRegistries] defined by the client modules.
    ///
    /// By default, the client connects to the `/command` endpoint for posting commands,
    /// to the `/query` endpoint for sending queries, and to `/subscription/create`,
    /// `/subscription/keep-up`, and `/subscription/cancel` endpoints to manage subscriptions.
    /// These endpoints can be changed via the [endpoints] parameter. If only a few of the endpoints
    /// need to be customized, submit only those to the `Endpoints` constructor and skip the others.
    ///
    /// Example:
    /// ```dart
    ///
    /// import 'package:example_dependency/types.dart' as dependencyTypes;
    /// import 'types.dart' as myTypes;
    ///
    /// var firebaseClient = RestClient(fb.FirebaseClient.anonymous(),
    ///                                 'https://example-org-42.firebaseio.com');
    /// var client = BackendClient('https://example.org',
    ///                            firebase: firebaseClient,
    ///                            typeRegistries: [myTypes.types(), dependencyTypes.types()]);
    /// ```
    /// or
    /// ```dart
    /// import 'package:example_dependency/types.dart' as dependencyTypes;
    /// import 'types.dart' as myTypes;
    ///
    /// var client = BackendClient('https://example.org',
    ///                            queryMode: QueryMode.DIRECT,
    ///                            typeRegistries: [myTypes.types(), dependencyTypes.types()]);
    /// ```
    ///
    BackendClient(String serverUrl,
                 {FirebaseClient firebase,
                  List<dynamic> typeRegistries = const [],
                  this.subscriptionKeepUpPeriod = _defaultSubscriptionKeepUpPeriod,
                  QueryMode queryMode = QueryMode.FIREBASE,
                  Endpoints endpoints})
            : _httpClient = HttpClient(serverUrl),
              _database = firebase,
              _queryProcessor = ArgumentError.checkNotNull(queryMode) == QueryMode.FIREBASE
                                ? FirebaseResponseProcessor(firebase)
                                : DirectResponseProcessor() {
        ArgumentError.checkNotNull(serverUrl);
        ArgumentError.checkNotNull(typeRegistries);
        this._endpoints = endpoints ?? Endpoints();
        theKnownTypes.registerAll(typeRegistries);
        Timer.periodic(subscriptionKeepUpPeriod, (timer) => _keepUpSubscriptions());
    }

    /// Posts a given [Command] to the server.
    Future<Ack> post(Command command) {
        var result = _httpClient
            .postMessage(_endpoints.command, command)
            .then(_parseAck);
        return result;
    }

    /// Obtains entities matching the given query from the server.
    ///
    /// Sends a [Query] to the server. If in `QueryMode.DIRECT` mode, the HTTP response contains
    /// a [QueryResponse]. If in `QueryMode.FIREBASE` mode, the HTTP response contains a path to
    /// a node in Firebase Realtime Database. The node's children represent the entities matching
    /// the query.
    ///
    /// Throws an exception if the query is invalid or if any kind of network or server error
    /// occurs.
    ///
    Stream<T> fetch<T extends GeneratedMessage>(Query query) {
        var httpResponse = _httpClient.postMessage(_endpoints.query, query);
        return _queryProcessor.process(httpResponse, query);
    }

    /// Subscribes to the changes of entities described by the given [topic].
    ///
    /// Sends a subscription request to the server and receives a path to the Firebase Realtime
    /// Database node where the entity changes are reflected.
    ///
    /// Based on the given location in the database, builds a [StateSubscription] which allows to listen
    /// to the entity or event changes in the convenient format of [Stream]s.
    ///
    /// Throws an exception if the query is invalid or if any kind of network or server error
    /// occurs.
    ///
    Future<StateSubscription<T>> subscribeTo<T extends GeneratedMessage>(pb.Topic topic) async {
        if (_database == null) {
            throw StateError('Cannot create a subscription. No Firebase client is provided.');
        }
        var targetTypeUrl = topic.target.type;
        var builder = theKnownTypes.findBuilderInfo(targetTypeUrl);
        if (builder == null) {
            throw ArgumentError.value(topic, 'topic', 'Target type `$targetTypeUrl` is unknown.');
        }
        var response = await _httpClient
            .postMessage(_endpoints.subscription.create, topic)
            .then(_parseFirebaseSubscription);

        StateSubscription<T> subscription = StateSubscription.of(response, _database);
        _activeSubscriptions.add(subscription);
        return subscription;
    }

    Ack _parseAck(http.Response response) {
        var ack = Ack();
        _parseInto(ack, response);
        return ack;
    }

    FirebaseSubscription _parseFirebaseSubscription(http.Response response) {
        var firebaseSubscription = FirebaseSubscription();
        _parseInto(firebaseSubscription, response);
        return firebaseSubscription;
    }

    void _keepUpSubscriptions() {
        _activeSubscriptions.forEach(_keepUpSubscription);
    }

    void _keepUpSubscription(StateSubscription subscription) {
        var subscriptionMessage = subscription.subscription;
        if (subscription.closed) {
            _cancel(subscriptionMessage);
            _activeSubscriptions.remove(subscription);
        } else {
            _keepUp(subscriptionMessage);
        }
    }

    void _keepUp(pb.Subscription subscription) {
        _httpClient.postMessage(_endpoints.subscription.keepUp, subscription);
    }

    void _cancel(pb.Subscription subscription) {
        _httpClient.postMessage(_endpoints.subscription.cancel, subscription);
    }
}

/// The mode in which the backend serves query responses.
enum QueryMode {

    /// HTTP responses received from backend are query responses.
    DIRECT,

    /// HTTP responses received from the backend are references in a Firebase database to where
    /// the actual query responses are.
    FIREBASE
}

/// URL paths to which the client should send requests.
///
class Endpoints {

    final String query;
    final String command;
    SubscriptionEndpoints _subscription;

    Endpoints({
        this.query = 'query',
        this.command = 'command',
        SubscriptionEndpoints subscription
    }) {
        ArgumentError.checkNotNull(query, 'query');
        ArgumentError.checkNotNull(command, 'command');
        this._subscription = subscription ?? SubscriptionEndpoints();
    }

    SubscriptionEndpoints get subscription {
        return _subscription;
    }
}

/// URL paths to which the client should send requests regarding entity and event subscriptions.
///
/// See [Endpoints].
///
class SubscriptionEndpoints {

    final String create;
    final String keepUp;
    final String cancel;

    SubscriptionEndpoints({
        this.create = 'subscription/create',
        this.keepUp = 'subscription/keep-up',
        this.cancel = 'subscription/cancel'
    }) {
        ArgumentError.checkNotNull(create, 'subscription.create');
        ArgumentError.checkNotNull(keepUp, 'subscription.keepUp');
        ArgumentError.checkNotNull(cancel, 'subscription.cancel');
    }
}
