/*
 * Copyright 2020, TeamDev. All rights reserved.
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
import 'package:spine_client/google/protobuf/field_mask.pb.dart';
import 'package:spine_client/spine/base/error.pb.dart' as pbError;
import 'package:spine_client/spine/base/field_path.pb.dart';
import 'package:spine_client/spine/client/filters.pb.dart';
import 'package:spine_client/spine/client/query.pb.dart';
import 'package:spine_client/spine/client/subscription.pb.dart' as pbSubscription;
import 'package:spine_client/spine/core/ack.pb.dart';
import 'package:spine_client/spine/core/command.pb.dart';
import 'package:spine_client/spine/core/diagnostics.pb.dart';
import 'package:spine_client/spine/core/event.pb.dart';
import 'package:spine_client/spine/core/tenant_id.pb.dart';
import 'package:spine_client/spine/core/user_id.pb.dart';
import 'package:spine_client/spine/time/time.pb.dart';
import 'package:spine_client/spine/web/firebase/subscription/firebase_subscription.pb.dart';
import 'package:spine_client/src/actor_request_factory.dart';
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/src/http_client.dart';
import 'package:spine_client/src/json.dart';
import 'package:spine_client/src/known_types.dart';
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
/// /// ...
///
/// var cmdRequest = client.command(postComment);
/// var events = cmdRequest.observeEvents(CommentPosted());
/// cmdRequest.post();
///
/// events.forEach((event) {
///     // Do something when an event is fired.
/// });
/// ```
///
class Clients {

    static final UserId DEFAULT_GUEST_ID = UserId()
        ..value = 'guest'
        ..freeze();

    final UserId _guestId;
    final TenantId _tenant;
    final HttpClient _httpClient;
    final ZoneOffset _zoneOffset;
    final ZoneId _zoneId;
    final FirebaseClient _firebase;
    final Endpoints _endpoints;
    final QueryResponseProcessor _queryProcessor;
    final Set<Client> _activeClients = Set();

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
    ///  - [typeRegistries] — a list of known type registries.
    /// ```
    ///
    Clients(String baseUrl,
           {UserId guestId,
            TenantId tenantId,
            ZoneOffset zoneOffset,
            ZoneId zoneId,
            QueryMode queryMode = QueryMode.FIREBASE,
            FirebaseClient firebase,
            Endpoints endpoints,
            Duration subscriptionKeepUpPeriod = const Duration(minutes: 2),
            List<dynamic> typeRegistries = const []}) :
            _httpClient = HttpClient(baseUrl),
            _guestId = guestId ?? DEFAULT_GUEST_ID,
            _tenant = tenantId,
            _zoneOffset = zoneOffset,
            _zoneId = zoneId,
            _queryProcessor = _chooseProcessor(queryMode, firebase),
            _endpoints = endpoints ?? Endpoints(),
            _firebase = firebase
    {
        _checkNonNullOrDefault(_guestId, 'guestId');
        ArgumentError.checkNotNull(subscriptionKeepUpPeriod, 'subscriptionKeepUpPeriod');
        theKnownTypes.registerAll(typeRegistries);
        Timer.periodic(subscriptionKeepUpPeriod,
                       (timer) => _refreshSubscriptions());
    }

    static void _checkNonNullOrDefault(GeneratedMessage argument, String name) {
        if (argument == null || isDefault(argument)) {
            throw ArgumentError.value(argument,
                name,
                '$name should not be null or default.');
        }
    }

    static QueryResponseProcessor _chooseProcessor(QueryMode queryMode, FirebaseClient firebase) {
        ArgumentError.checkNotNull(queryMode, 'queryMode');
        return queryMode == QueryMode.FIREBASE
               ? FirebaseResponseProcessor(firebase)
               : DirectResponseProcessor();
    }

    Client asGuest() {
        ActorRequestFactory requests = _requests(_guestId);
        return _newClient(requests);
    }

    Client onBehalfOf(UserId user) {
        ActorRequestFactory requests = _requests(_guestId);
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

class Client {

    final HttpClient _httpClient;
    final ActorRequestFactory _requests;
    final FirebaseClient _firebase;
    final Endpoints _endpoints;
    final QueryResponseProcessor _queryProcessor;
    final Set<Subscription> _activeSubscriptions = Set();

    Client._(this._httpClient,
             this._requests,
             this._firebase,
             this._endpoints,
             this._queryProcessor);

    CommandRequest<M> command<M extends GeneratedMessage>(M commandMessage) {
        ArgumentError.checkNotNull(commandMessage, 'command message');
        return CommandRequest(this, commandMessage, );
    }

    QueryRequest<M> select<M extends GeneratedMessage>(M prototype) {
        ArgumentError.checkNotNull(prototype, 'entity state type');
        return QueryRequest(this, prototype);
    }

    StateSubscriptionRequest<M> subscribeTo<M extends GeneratedMessage>(M prototype) {
        ArgumentError.checkNotNull(prototype, 'entity state type');
        return StateSubscriptionRequest(this, prototype);
    }

    EventSubscriptionRequest<M> subscribeToEvents<M extends GeneratedMessage>(M prototype) {
        ArgumentError.checkNotNull(prototype, 'event type');
        return EventSubscriptionRequest(this, prototype);
    }

    void cancelAllSubscriptions() {
        for (Subscription subscription in _activeSubscriptions) {
            subscription.unsubscribe();
            subscription.subscription.then(_cancel);
        }
        _activeSubscriptions.clear();
    }

    Future<void> _postCommand(Command command, CommandErrorCallback onError) {
        var response = _httpClient.postMessage(_endpoints.command, command);
        return response.then((response) {
            var ack = Ack();
            parseInto(ack, response.body);
            if (ack.status.hasError() && onError != null) {
                onError(ack.status.error);
            }
        });
    }

    EventSubscription<E>
    _subscribeToEvents<E extends GeneratedMessage>(pbSubscription.Topic topic) {
        return _subscribe(topic, (s, d) => EventSubscription.of(s, d));
    }

    StateSubscription<S>
    _subscribeToStateUpdates<S extends GeneratedMessage>(pbSubscription.Topic topic,
                                                         BuilderInfo builderInfo) {
        return _subscribe(topic, (s, d) => StateSubscription.of(s, builderInfo, d));
    }

    S _subscribe<S extends Subscription>(pbSubscription.Topic topic,
                                         CreateSubscription<S> newSubscription) {
        if (_firebase == null) {
            throw StateError('Cannot create a subscription. No Firebase client is provided.');
        }
        var targetTypeUrl = topic.target.type;
        var builder = theKnownTypes.findBuilderInfo(targetTypeUrl);
        if (builder == null) {
            throw ArgumentError.value(topic, 'topic', 'Target type `$targetTypeUrl` is unknown.');
        }
        var fbSubscription = _httpClient
            .postMessage(_endpoints.subscription.create, topic)
            .then(_parseFirebaseSubscription);
        return newSubscription(fbSubscription, _firebase);
    }

    FirebaseSubscription _parseFirebaseSubscription(http.Response response) {
        var firebaseSubscription = FirebaseSubscription();
        parseInto(firebaseSubscription, response.body);
        return firebaseSubscription;
    }

    Stream<S> _execute<S extends GeneratedMessage>(Query query) {
        var httpResponse = _httpClient.postMessage(_endpoints.query, query);
        return _queryProcessor.process(httpResponse, query);
    }

    void _refreshSubscriptions() {
        _activeSubscriptions.forEach(_refreshSubscription);
    }

    void _refreshSubscription(Subscription subscription) {
        var subscriptionMessage = subscription.subscription;
        if (subscription.closed) {
            subscriptionMessage.then(_cancel);
            _activeSubscriptions.remove(subscription);
        } else {
            subscriptionMessage.then(_keepUp);
        }
    }

    void _keepUp(pbSubscription.Subscription subscription) {
        _httpClient.postMessage(_endpoints.subscription.keepUp, subscription);
    }

    void _cancel(pbSubscription.Subscription subscription) {
        _httpClient.postMessage(_endpoints.subscription.cancel, subscription);
    }
}

typedef CreateSubscription<S extends Subscription> =
    S Function(Future<FirebaseSubscription>, FirebaseClient);

CompositeFilter all(Iterable<Filter> filters) {
    ArgumentError.checkNotNull(filters);
    return CompositeFilter()
        ..operator = CompositeFilter_CompositeOperator.ALL
        ..filter.addAll(filters)
        ..freeze();
}

CompositeFilter either(Iterable<Filter> filters) {
    ArgumentError.checkNotNull(filters);
    return CompositeFilter()
        ..operator = CompositeFilter_CompositeOperator.EITHER
        ..filter.addAll(filters)
        ..freeze();
}

Filter eq(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.EQUAL, value);

Filter le(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.LESS_OR_EQUAL, value);

Filter ge(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.GREATER_OR_EQUAL, value);

Filter lt(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.LESS_THAN, value);

Filter gt(String fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.GREATER_THAN, value);

Filter _filter(String fieldPath, Filter_Operator operator, Object value) {
    ArgumentError.checkNotNull(fieldPath);
    ArgumentError.checkNotNull(value);
    var pathElements = fieldPath.split('.');
    return Filter()
        ..fieldPath = (FieldPath()..fieldName.addAll(pathElements))
        ..operator = operator
        ..value = packObject(value)
        ..freeze();
}

class CommandRequest<M extends GeneratedMessage> {

    final Client _client;
    final Command _command;
    final List<EventSubscription> _subscriptions = [];

    CommandRequest(this._client, M command) :
            _command = _client._requests.command().create(command);

    Stream<E> observeEvents<E extends GeneratedMessage>(E prototype) =>
        _observeEvents(prototype).eventMessages;

    Stream<Event> observeEventsWithContexts(GeneratedMessage prototype) =>
        _observeEvents(prototype).events;

    EventSubscription<E> _observeEvents<E extends GeneratedMessage>(E prototype) {
        var subscription = _client.subscribeToEvents(prototype)
            .where(all([eq('context.past_message', _commandAsOrigin())]))
            .post();
        _subscriptions.add(subscription);
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

    Future<void> post({CommandErrorCallback onError}) {
        if (_subscriptions.isEmpty) {
            throw StateError('Use `observeEvents(..)` or `observeEventsWithContexts(..)` to observe'
                ' command results or call `postAndForget()` instead of `post()` if you observe'
                ' command results elsewhere.');
        }
        return Future.wait(_subscriptions.map((s) => s.subscription))
                     .then((_) => _client._postCommand(_command, onError));
    }

    Future<void> postAndForget({CommandErrorCallback onError}) {
        if (_subscriptions.isNotEmpty) {
            throw StateError('Use `post()` to add event subscriptions.');
        }
        return _client._postCommand(_command, onError);
    }
}

class QueryRequest<M extends GeneratedMessage> {

    final Client _client;
    final M _prototype;

    final Set<Object> _ids = Set();
    final Set<CompositeFilter> _filters = Set();
    final Set<String> _fields = Set();
    OrderBy _orderBy;
    int _limit;


    QueryRequest(this._client, this._prototype);

    QueryRequest<M> fields(List<String> fieldPaths) {
        ArgumentError.checkNotNull(fieldPaths, 'field paths');
        _fields.addAll(fieldPaths);
        return this;
    }

    QueryRequest<M> where(CompositeFilter filter) {
        ArgumentError.checkNotNull(filter, 'filter');
        _filters.add(filter);
        return this;
    }

    QueryRequest<M> whereIds(Iterable<Object> ids) {
        ArgumentError.checkNotNull(ids, 'ids');
        _ids.addAll(ids);
        return this;
    }

    QueryRequest<M> orderBy(String column, OrderBy_Direction direction) {
        ArgumentError.checkNotNull(column, 'column');
        ArgumentError.checkNotNull(direction, 'direction');
        _orderBy = OrderBy()
            ..column = column
            ..direction = direction;
        return this;
    }

    QueryRequest<M> limit(int count) {
        ArgumentError.checkNotNull(count, 'limit');
        if (count <= 0) {
            throw ArgumentError('Invalid value of limit = $count');
        }
        _limit = count;
        return this;
    }

    Stream<M> post() {
        var mask = FieldMask()
            ..paths.addAll(_fields);
        var query = _client._requests.query().build(
            _prototype,
            ids: _ids,
            filters: _filters,
            fieldMask: mask,
            orderBy: _orderBy,
            limit: _limit
        );
        return _client._execute(query);
    }
}

class StateSubscriptionRequest<M extends GeneratedMessage> {

    final Client _client;
    final M _prototype;
    final Set<Object> _ids = Set();
    final Set<CompositeFilter> _filters = Set();

    StateSubscriptionRequest(this._client, this._prototype);

    StateSubscriptionRequest<M> where(CompositeFilter filter) {
        ArgumentError.checkNotNull(filter, 'filter');
        _filters.add(filter);
        return this;
    }

    StateSubscriptionRequest<M> whereIdIn(Iterable<Object> ids) {
        ArgumentError.checkNotNull(ids, 'ids');
        _ids.addAll(ids);
        return this;
    }

    StateSubscription<M> post() {
        var topic = _client._requests.topic().withFilters(_prototype, ids: _ids, filters: _filters);
        return _client._subscribeToStateUpdates(topic, _prototype.info_);
    }
}

class EventSubscriptionRequest<M extends GeneratedMessage> {

    final M _prototype;
    final Client _client;
    final List<CompositeFilter> _filers = [];

    EventSubscriptionRequest(this._client, this._prototype);

    EventSubscriptionRequest<M> where(CompositeFilter filter) {
        ArgumentError.checkNotNull(filter, 'filter');
        _filers.add(filter);
        return this;
    }

    EventSubscription<M> post() {
        var topic = _client._requests.topic().withFilters(_prototype, filters: _filers);
        return _client._subscribeToEvents(topic);
    }
}

typedef CommandErrorCallback = void Function(pbError.Error error);

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
