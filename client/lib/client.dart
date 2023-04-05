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

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/firebase_client.dart';
import 'package:spine_client/google/protobuf/field_mask.pb.dart';
import 'package:spine_client/http_client.dart';
import 'package:spine_client/known_types.dart';
import 'package:spine_client/spine/base/error.pb.dart' as pbError;
import 'package:spine_client/spine/base/field_path.pb.dart';
import 'package:spine_client/spine/client/filters.pb.dart';
import 'package:spine_client/spine/client/query.pb.dart';
import 'package:spine_client/spine/client/subscription.pb.dart' as pbSubscription;
import 'package:spine_client/spine/core/ack.pb.dart';
import 'package:spine_client/spine/core/command.pb.dart';
import 'package:spine_client/spine/core/diagnostics.pb.dart';
import 'package:spine_client/spine/core/tenant_id.pb.dart';
import 'package:spine_client/spine/core/user_id.pb.dart';
import 'package:spine_client/spine/time/time.pb.dart';
import 'package:spine_client/spine/web/firebase/subscription/firebase_subscription.pb.dart';
import 'package:spine_client/src/actor_request_factory.dart';
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/src/query_processor.dart';
import 'package:spine_client/subscription.dart';
import 'package:spine_client/validate.dart';

/// A factory of [Client]s.
///
/// Creates [Clients] for posting commands, sending queries, and managing subscriptions on behalf
/// of a certain user.
///
/// Example:
/// ```dart
/// import 'package:spine_client/client.dart';
/// import './types.dart' as myTypes;
///
/// var clients = Clients(
///     'https://example.org/',
///     firebase: WebFirebaseClient(FirebaseApp().database),
///     typeRegistries: [myTypes.types()]
/// );
/// var actor = UserId()
///     ..value = 'some-user-id';
/// var client = clients.onBehalfOf(actor);
///
/// // ...
///
/// var cmdRequest = client.command(postComment);
/// var events = cmdRequest.observeEvents<CommentPosted>();
/// cmdRequest.post();
///
/// events.forEach((event) {
///     // Do something when an event is fired.
/// });
/// ```
///
class Clients {

    static final UserId _DEFAULT_GUEST_ID = UserId()
        ..value = 'guest'
        ..freeze();

    final UserId _guestId;
    final TenantId? _tenant;
    final HttpClient _httpClient;
    final ZoneOffset? _zoneOffset;
    final ZoneId? _zoneId;
    final FirebaseClient? _firebase;
    final Endpoints _endpoints;
    final Set<Client> _activeClients = Set();
    late QueryProcessor _queryProcessor;

    /// Creates a new instance of `Clients`.
    ///
    /// Parameters:
    ///  - [baseUrl] — the base URL of the server which receives the requests from the clients;
    ///  - [guestId] — the default `UserId` to use in the "guest" mode;
    ///    the default is `UserId(value = "guest")`;
    ///  - [tenantId] — the tenant ID; use this argument only in multitenant systems;
    ///  - [zoneOffset] and [zoneId] — the time zone in which the created clients operate;
    ///    by default, uses the system time zone;
    ///  - [queryMode] — the query processing mode which should be used by the created clients;
    ///    see [QueryMode] for more info; the default value is `FIREBASE`;
    ///  - [firebase] — a [FirebaseClient] which precesses queries and subscriptions;
    ///    if [queryMode] is [QueryMode.DIRECT] and subscriptions are not required, this argument
    ///    can be skipped;
    ///  - [endpoints] — the custom endpoints of the backend; see [Endpoints] for the defaults;
    ///  - [subscriptionKeepUpPeriod] — the time between subscription keep-up requests;
    ///    2 minutes by default;
    ///  - [onNetworkError] — a callback handling network errors;
    ///    should receive either error as the only argument or error and [StackTrace];
    ///    should return a `FutureOr<Response>`;
    ///  - [typeRegistries] — a list of known type registries; the `dart_code_gen` tool generates
    ///    the `types.dart` files for each module for main and test scopes. A `types.dart` file
    ///    contains information about the known Protobuf types of this module. See the class level
    ///    doc for an example of how to access a type registry and pass it to this constructor;
    ///  - [httpTranslator] — a custom instance of [HttpTranslator], which allows to configure
    ///    how HTTP requests are sent, and how their responses are treated. By default,
    ///    a new instance of [HttpTranslator] will be used.
    ///
    Clients(String baseUrl,
           {UserId? guestId = null,
            TenantId? tenantId = null,
            ZoneOffset? zoneOffset = null,
            ZoneId? zoneId = null,
            QueryMode queryMode = QueryMode.FIREBASE,
            FirebaseClient? firebase = null,
            Endpoints? endpoints = null,
            Duration subscriptionKeepUpPeriod = const Duration(minutes: 2),
            List<dynamic> typeRegistries = const [],
            HttpTranslator? httpTranslator = null}) :
            _httpClient = _createHttpClient(baseUrl, httpTranslator),
            _guestId = guestId ?? _DEFAULT_GUEST_ID,
            _tenant = tenantId,
            _zoneOffset = zoneOffset,
            _zoneId = zoneId,
            _endpoints = endpoints ?? Endpoints(),
            _firebase = firebase
    {
        _checkNonNullOrDefault(_guestId, 'guestId');
        _queryProcessor = _chooseProcessor(queryMode, _httpClient, firebase);
        theKnownTypes.registerAll(typeRegistries);
        Timer.periodic(subscriptionKeepUpPeriod,
                       (timer) => _refreshSubscriptions());
    }

    static void _checkNonNullOrDefault(GeneratedMessage argument, String name) {
        if (isDefault(argument)) {
            throw ArgumentError.value(argument,
                name,
                '$name should have a non-default value.');
        }
    }

    static HttpClient _createHttpClient(String baseUrl, HttpTranslator? httpTranslator) {
        if(httpTranslator == null) {
            return HttpClient(baseUrl);
        }
        return HttpClient.withTranslator(baseUrl, httpTranslator);
    }

    static QueryProcessor
    _chooseProcessor(QueryMode queryMode, HttpClient httpClient, FirebaseClient? firebase) {
        return queryMode == QueryMode.FIREBASE
               ? FirebaseQueryProcessor(firebase!, httpClient)
               : DirectQueryProcessor(httpClient);
    }

    /// Creates a new client which sends requests on behalf of a guest user.
    ///
    /// Specify `guestId` when creating `Clients` to change the placeholder ID for the guest user.
    ///
    Client asGuest() {
        ActorRequestFactory requests = _requests(_guestId);
        return _newClient(requests);
    }

    /// Creates a new client which sends requests on behalf of the given user.
    ///
    Client onBehalfOf(UserId user) {
        ActorRequestFactory requests = _requests(user);
        return _newClient(requests);
    }

    Client _newClient(ActorRequestFactory requests) =>
        Client._(_httpClient,
                 requests,
                 _firebase,
                 _endpoints,
                 _queryProcessor);

    ActorRequestFactory _requests(UserId actor) =>
        ActorRequestFactory(actor, _tenant, _zoneOffset, _zoneId);

    /// Cancels all the active subscriptions
    void cancelAllSubscriptions() {
        for (var client in _activeClients) {
            client.cancelAllSubscriptions();
        }
        _activeClients.clear();
    }

    void _refreshSubscriptions() {
        for (var client in _activeClients) {
            client._refreshSubscriptions();
        }
    }
}

/// A client which connects to a Spine-based backend, posts commands, sends queries, and creates
/// and managed subscriptions on behalf of a certain user.
///
class Client {

    final HttpClient _httpClient;
    final ActorRequestFactory _requests;
    final FirebaseClient? _firebase;
    final Endpoints _endpoints;
    final QueryProcessor _queryProcessor;
    final Set<Subscription> _activeSubscriptions = Set();

    Client._(this._httpClient,
             this._requests,
             this._firebase,
             this._endpoints,
             this._queryProcessor);

    /// Constructs a request to post a command to the server.
    CommandRequest<M> command<M extends GeneratedMessage>(M commandMessage) {
        return CommandRequest._(this, commandMessage, );
    }

    /// Constructs a request to send a query to the server.
    QueryRequest<M> select<M extends GeneratedMessage>() {
        var type = M;
        return QueryRequest._(this, type);
    }

    /// Constructs a request to create an entity state subscription.
    StateSubscriptionRequest<M> subscribeTo<M extends GeneratedMessage>() {
        var type = M;
        return StateSubscriptionRequest._(this, type);
    }

    /// Constructs a request to create an event subscription.
    EventSubscriptionRequest<M> subscribeToEvents<M extends GeneratedMessage>() {
        var type = M;
        return EventSubscriptionRequest._(this, type);
    }

    /// Cancels all the subscriptions created by this client.
    void cancelAllSubscriptions() {
        for (Subscription subscription in _activeSubscriptions) {
            subscription.unsubscribe();
            _cancel(subscription.subscription);
        }
        _activeSubscriptions.clear();
    }

    Future<void> _postCommand(Command command, CommandErrorCallback? onError) {
        var translated = _httpClient.postAndTranslate(_endpoints.command, command, Ack());
        return translated.then((ack) {
            if (ack.status.hasError() && onError != null) {
                onError(ack.status.error);
            }
        });
    }

    Future<EventSubscription<E>>
    _subscribeToEvents<E extends GeneratedMessage>(pbSubscription.Topic topic) {
        return _subscribe(topic, (s, d) => EventSubscription.of(s, d));
    }

    Future<StateSubscription<S>>
    _subscribeToStateUpdates<S extends GeneratedMessage>(pbSubscription.Topic topic,
                                                         BuilderInfo builderInfo) {
        return _subscribe(topic, (s, d) => StateSubscription.of(s, builderInfo, d));
    }

    Future<S> _subscribe<S extends Subscription>(pbSubscription.Topic topic,
                                                 _CreateSubscription<S> newSubscription) {
        if (_firebase == null) {
            throw StateError('Cannot create a subscription. No Firebase client is provided.');
        }
        var targetTypeUrl = topic.target.type;
        var builder = theKnownTypes.findBuilderInfo(targetTypeUrl);
        if (builder == null) {
            throw ArgumentError.value(topic, 'topic', 'Target type `$targetTypeUrl` is unknown.');
        }
        var subscription =
        _httpClient.postAndTranslate(_endpoints.subscription.create, topic, FirebaseSubscription())
            .then((value) => newSubscription(value, _firebase!));
        return subscription;
    }

    Stream<S> _execute<S extends GeneratedMessage>(Query query) {
        return _queryProcessor.execute(query, _endpoints.query);
    }

    void _refreshSubscriptions() {
        _activeSubscriptions.forEach(_refreshSubscription);
    }

    void _refreshSubscription(Subscription subscription) {
        var subscriptionMessage = subscription.subscription;
        if (subscription.closed) {
            _cancel(subscriptionMessage);
            _activeSubscriptions.remove(subscription);
        } else {
            _keepUp(subscriptionMessage);
        }
    }

    void _keepUp(pbSubscription.Subscription subscription) {
        _httpClient.postMessage(_endpoints.subscription.keepUp, subscription);
    }

    void _cancel(pbSubscription.Subscription subscription) {
        _httpClient.postMessage(_endpoints.subscription.cancel, subscription);
    }
}

/// A function which accepts a future of `FirebaseSubscription` and a firebase client and creates
/// an instance of [Subscription].
typedef _CreateSubscription<S extends Subscription> =
    S Function(FirebaseSubscription, FirebaseClient);

/// A simple or a composite field filter.
///
abstract class FilterOrComposite {

    /// Obtains the Protobuf `CompositeFilter` representing this filter.
    CompositeFilter _toProto();
}

/// A composite field filter.
///
class Composite implements FilterOrComposite {

    final CompositeFilter filter;

    Composite._(this.filter);

    @override
    CompositeFilter _toProto() {
        return filter;
    }
}

/// A simple field filter.
///
/// A single simple filter is represented as a `CompositeFilter` by wrapping it into the composite
/// filter with the `AND` operator.
///
class SimpleFilter implements FilterOrComposite {

    final Filter filter;

    SimpleFilter._(this.filter);

    @override
    CompositeFilter _toProto() {
        return CompositeFilter()
            ..filter.add(filter)
            ..operator = CompositeFilter_CompositeOperator.ALL
            ..freeze();
    }
}

/// Creates a composite filter which groups one or more field filters with the `ALL` operator.
///
/// All the field filters should pass in order for the composite filter to pass.
///
Composite all(Iterable<SimpleFilter> filters) {
    return Composite._(CompositeFilter()
        ..operator = CompositeFilter_CompositeOperator.ALL
        ..filter.addAll(filters.map((f) => f.filter))
        ..freeze());
}

/// Creates a composite filter which groups one or more field filters with the `EITHER` operator.
///
/// At least one field filter should pass in order for the composite filter to pass.
///
Composite either(Iterable<SimpleFilter> filters) {
    return Composite._(CompositeFilter()
        ..operator = CompositeFilter_CompositeOperator.EITHER
        ..filter.addAll(filters.map((f) => f.filter))
        ..freeze());
}

/// Creates a field filter with the `=` operator.
SimpleFilter eq(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.EQUAL, value);

/// Creates a field filter with the `<=` operator.
SimpleFilter le(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.LESS_OR_EQUAL, value);

/// Creates a field filter with the `>=` operator.
SimpleFilter ge(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.GREATER_OR_EQUAL, value);

/// Creates a field filter with the `<` operator.
SimpleFilter lt(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.LESS_THAN, value);

/// Creates a field filter with the `>` operator.
SimpleFilter gt(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.GREATER_THAN, value);

SimpleFilter _filter(String fieldPath, Filter_Operator operator, Object value) {
    var pathElements = fieldPath.split('.');
    return SimpleFilter._(Filter()
        ..fieldPath = (FieldPath()..fieldName.addAll(pathElements))
        ..operator = operator
        ..value = packObject(value)
        ..freeze());
}

/// A request to the server to post a command.
class CommandRequest<M extends GeneratedMessage> {

    final Client _client;
    final Command _command;
    final List<Future<EventSubscription>> _futureSubscriptions = [];

    CommandRequest._(this._client, M command) :
            _command = _client._requests.command().create(command);

    /// Creates an event subscription for events produced as a direct result of this command.
    ///
    /// Events down the line, i.e. events produced as the result of other messages which where
    /// produced as the result of this command, do not match this subscription.
    ///
    /// When the resulting future completes, the subscription is guaranteed to be created.
    /// Also, when the future created in `post(..)` completes, the all subscriptions created within
    /// the same `CommandRequest` are guaranteed to have completed.
    ///
    Future<EventSubscription<E>> observeEvents<E extends GeneratedMessage>() {
        var subscription = _client.subscribeToEvents<E>()
            .where(eq('context.past_message', _commandAsOrigin()))
            .post();
        _futureSubscriptions.add(subscription);
        return subscription;
    }

    Origin _commandAsOrigin() {
        MessageId id = MessageId()
            ..id = pack(_command.id)
            ..typeUrl = _command.message.typeUrl;
        return Origin()
            ..message = id
            ..actorContext = _command.context.actorContext;
    }

    /// Asynchronously sends this request to the server.
    ///
    /// Fails if there are no event subscriptions to monitor the command execution. If this is
    /// the desired behaviour, use `CommandRequest.postAndForget(..)`.
    ///
    /// When the command is sent, the event subscriptions created within this request
    /// are guaranteed to be active.
    ///
    /// Returns a future which completes when the request is sent. If there was a network problem,
    /// the future, completes with an error.
    ///
    /// If the server rejects the command with an error and the [onError] callback is set,
    /// the callback will be triggered with the error. Otherwise, the error is silently ignored.
    ///
    Future<void> post({CommandErrorCallback? onError}) {
        if (_futureSubscriptions.isEmpty) {
            throw StateError('Use `observeEvents(..)` or `observeEventsWithContexts(..)` to observe'
                ' command results or call `postAndForget()` instead of `post()` if you observe'
                ' command results elsewhere.');
        }
        return Future.wait(_futureSubscriptions)
                     .then((_) => _client._postCommand(_command, onError));
    }

    /// Asynchronously sends this request to the server.
    ///
    /// Fails if there are any event subscriptions to monitor the command execution. Use
    /// `CommandRequest.post(..)` for such scenarios.
    ///
    /// Returns a future which completes when the request is sent. If there was a network problem,
    /// the future, completes with an error.
    ///
    /// If the server rejects the command with an error and the [onError] callback is set,
    /// the callback will be triggered with the error. Otherwise, the error is silently ignored.
    ///
    Future<void> postAndForget({CommandErrorCallback? onError}) {
        if (_futureSubscriptions.isNotEmpty) {
            throw StateError('Use `post()` to add event subscriptions.');
        }
        return _client._postCommand(_command, onError);
    }
}

/// A callback which notifies the user about an error when posting a command.
///
/// A server may reject a command for several reasons. For example, a command type may not be
/// supported by the target server. In such cases, the server acknowledges the command and responds
/// with a `spine.base.Error`.
///
/// To find out the actual reason of the error, explore the `Error.type` and `Error.code`.
///
typedef CommandErrorCallback = void Function(pbError.Error error);

/// A request to query the server for data.
///
class QueryRequest<M extends GeneratedMessage> {

    final Client _client;
    final Type _type;

    final Set<Object> _ids = Set();
    final Set<CompositeFilter> _filters = Set();
    final Set<String> _fields = Set();
    OrderBy? _orderBy;
    int? _limit;

    QueryRequest._(this._client, this._type);

    /// Specifies the fields to include in the query result.
    ///
    /// By default, all the fields are included.
    ///
    QueryRequest<M> fields(List<String> fieldPaths) {
        _fields.addAll(fieldPaths);
        return this;
    }

    /// Adds field filters for the query results.
    ///
    /// See `all(..)`, `either(..)`, `eq(..)`, `le(..)`, `ge(..)`, `lt(..)`, `gt(..)`.
    ///
    /// If called multiple times, the composite filters are composed with the `ALL` operator, i.e.
    /// an entity state should pass all of the composite filters to be included in the query
    /// results.
    ///
    QueryRequest<M> where(FilterOrComposite filter) {
        _filters.add(filter._toProto());
        return this;
    }

    /// Adds IDs to the query.
    ///
    /// Only entities with the given IDs are included in the query results.
    ///
    /// If called multiple times, the IDs add up.
    ///
    QueryRequest<M> whereIds(Iterable<Object> ids) {
        _ids.addAll(ids);
        return this;
    }

    /// Adds ordering to this query.
    ///
    /// The query results will be ordered by the given column. Specify the [direction] parameter
    /// to change the ordering direction (ascending by default).
    ///
    QueryRequest<M> orderBy(String column,
                            [OrderBy_Direction direction = OrderBy_Direction.ASCENDING]) {
        _orderBy = OrderBy()
            ..column = column
            ..direction = direction;
        return this;
    }

    /// Adds a limit to the number of returned entity states.
    ///
    /// A limit can only be used along with `orderBy(..)`.
    ///
    QueryRequest<M> limit(int count) {
        if (count <= 0) {
            throw ArgumentError('Invalid value of limit = $count');
        }
        _limit = count;
        return this;
    }

    /// Asynchronously sends this request to the server.
    ///
    /// Returns a stream of query results. If there was a network problem, the stream has an error.
    ///
    Stream<M> post() {
        var mask = FieldMask()
            ..paths.addAll(_fields);
        var query = _client._requests.query().build(
            _type,
            ids: _ids,
            filters: _filters,
            fieldMask: mask,
            orderBy: _orderBy,
            limit: _limit
        );
        return _client._execute(query);
    }
}

/// A request to subscribe to entity state updates.
///
class StateSubscriptionRequest<M extends GeneratedMessage> {

    final Client _client;
    final Type _type;
    final Set<Object> _ids = Set();
    final Set<CompositeFilter> _filters = Set();

    StateSubscriptionRequest._(this._client, this._type);

    /// Adds field filters to the subscription.
    ///
    /// See `all(..)`, `either(..)`, `eq(..)`, `le(..)`, `ge(..)`, `lt(..)`, `gt(..)`.
    ///
    /// If called multiple times, the composite filters are composed with the `ALL` operator, i.e.
    /// an entity state should pass all of the composite filters to match the subscription.
    ///
    StateSubscriptionRequest<M> where(FilterOrComposite filter) {
        _filters.add(filter._toProto());
        return this;
    }

    /// Adds an ID filter to the subscription.
    ///
    /// Only entities with the given IDs match the subscription.
    ///
    /// If called multiple times, the IDs add up.
    ///
    StateSubscriptionRequest<M> whereIdIn(Iterable<Object> ids) {
        _ids.addAll(ids);
        return this;
    }

    /// Asynchronously sends this request to the server.
    ///
    /// The subscription is guaranteed to have been created on server when the resulting future
    /// completes.
    ///
    Future<StateSubscription<M>> post() {
        var topic = _client._requests.topic().withFilters(_type, ids: _ids, filters: _filters);
        var builderInfo = theKnownTypes.findBuilderInfo(theKnownTypes.typeUrlFrom(_type))!;
        return _client._subscribeToStateUpdates(topic, builderInfo);
    }
}

/// A request to subscribe to events.
///
class EventSubscriptionRequest<M extends GeneratedMessage> {

    final Client _client;
    final Type _type;
    final List<CompositeFilter> _filers = [];

    EventSubscriptionRequest._(this._client, this._type);

    /// Adds field filters to the subscription.
    ///
    /// See `all(..)`, `either(..)`, `eq(..)`, `le(..)`, `ge(..)`, `lt(..)`, `gt(..)`.
    ///
    /// If called multiple times, the composite filters are composed with the `ALL` operator, i.e.
    /// an event should pass all of the composite filters to match the subscription.
    ///
    EventSubscriptionRequest<M> where(FilterOrComposite filter) {
        _filers.add(filter._toProto());
        return this;
    }

    /// Asynchronously sends this request to the server.
    ///
    /// The subscription is guaranteed to have been created on server when the resulting future
    /// completes.
    ///
    Future<EventSubscription<M>> post() {
        var topic = _client._requests.topic().withFilters(_type, filters: _filers);
        return _client._subscribeToEvents(topic);
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

/// A part of URL path, specifying a destination of client requests of some type.
///
typedef UrlPath = String;

/// URL paths to which the client should send requests.
///
class Endpoints {

    final UrlPath query;
    final UrlPath command;
    late SubscriptionEndpoints _subscription;

    Endpoints({
        this.query = 'query',
        this.command = 'command',
        SubscriptionEndpoints? subscription
    }) {
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

    final UrlPath create;
    final UrlPath keepUp;
    final UrlPath cancel;

    SubscriptionEndpoints({
        this.create = 'subscription/create',
        this.keepUp = 'subscription/keep-up',
        this.cancel = 'subscription/cancel'
    });
}
