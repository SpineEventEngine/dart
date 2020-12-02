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

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/actor_request_factory.dart';
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
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/src/http_client.dart';
import 'package:spine_client/src/json.dart';
import 'package:spine_client/src/query_processor.dart';
import 'package:spine_client/subscription.dart';
import 'package:spine_client/validate.dart';

import 'backend_client.dart';
import 'firebase_client.dart';

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
    final Set<Subscription> _activeSubscriptions = Set();
    final NetworkErrorCallback _networkErrorCallback;

    Clients(String baseUrl,
           {UserId guestId,
            TenantId tenantId,
            ZoneOffset zoneOffset,
            ZoneId zoneId,
            FirebaseClient firebase,
            Endpoints endpoints,
            Duration subscriptionKeepUpPeriod = const Duration(minutes: 2),
            QueryMode queryMode = QueryMode.FIREBASE,
            NetworkErrorCallback onNetworkError}) :
            _httpClient = HttpClient(baseUrl),
            _guestId = guestId ?? DEFAULT_GUEST_ID,
            _tenant = tenantId,
            _zoneOffset = zoneOffset,
            _zoneId = zoneId,
            _queryProcessor = _chooseProcessor(queryMode, firebase),
            _endpoints = endpoints ?? Endpoints(),
            _firebase = firebase,
            _networkErrorCallback = onNetworkError
    {
        _checkNonNullOrDefault(_guestId, 'guestId');
        ArgumentError.checkNotNull(
            subscriptionKeepUpPeriod, 'subscriptionKeepUpPeriod'
        );
        Timer.periodic(subscriptionKeepUpPeriod,
                       (timer) => _keepUpSubscriptions());
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
                 _queryProcessor,
                 _networkErrorCallback);

    ActorRequestFactory _requests(UserId actor) =>
        ActorRequestFactory(actor, _tenant, _zoneOffset, _zoneId);

    void _checkNonNullOrDefault(GeneratedMessage argument, String name) {
        if (argument == null || isDefault(argument)) {
            throw ArgumentError.value(argument,
                                      name,
                                      '$name should not be null or default.');
        }
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

    void _keepUp(pbSubscription.Subscription subscription) {
        _httpClient.postMessage(_endpoints.subscription.keepUp, subscription);
    }

    void _cancel(pbSubscription.Subscription subscription) {
        _httpClient.postMessage(_endpoints.subscription.cancel, subscription);
    }
}

class Client {

    final HttpClient _httpClient;
    final ActorRequestFactory _requests;
    final FirebaseClient _firebase;
    final Endpoints _endpoints;
    final QueryResponseProcessor _queryProcessor;
    final NetworkErrorCallback _networkErrorCallback;

    Client._(this._httpClient,
             this._requests,
             this._firebase,
             this._endpoints,
             this._queryProcessor,
             this._networkErrorCallback);

    CommandRequest<M> command<M extends GeneratedMessage>(M commandMessage) {
        ArgumentError.checkNotNull(commandMessage, 'command message');
        return CommandRequest(this, commandMessage, );
    }

    QueryRequest<M> select<M extends GeneratedMessage>(M prototype) {

    }

    SubscriptionRequest subscribeTo<M extends GeneratedMessage>(M prototype) {

    }

    SubscriptionRequest subscribeToEvents<M extends GeneratedMessage>(M prototype) {

    }

    void _postCommand(Command command, CommandErrorCallback onError) {
        _httpClient.postMessage(_endpoints.command, command)
            .catchError(_networkErrorCallback)
            .then((response) {
                var ack = Ack();
                parseInto(ack, response.body);
                if (ack.status.hasError() && onError != null) {
                    onError(ack.status.error);
                }
        });
    }

    EventSubscription<E>
    _subscribeToEvents<E extends GeneratedMessage>(pbSubscription.Topic topic) {

    }

    StateSubscription<S>
    _subscribeToStateUpdates<S extends GeneratedMessage>(pbSubscription.Topic topic) {

    }
}

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

Filter eq(List<String> fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.EQUAL, value);

Filter le(List<String> fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.LESS_OR_EQUAL, value);

Filter ge(List<String> fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.GREATER_OR_EQUAL, value);

Filter lt(List<String> fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.LESS_THAN, value);

Filter gt(List<String> fieldPath, Object value) =>
    _filter(fieldPath, Filter_Operator.GREATER_THAN, value);

Filter _filter(List<String> fieldPath, Filter_Operator operator, Object value) {
    ArgumentError.checkNotNull(fieldPath);
    ArgumentError.checkNotNull(value);
    return Filter()
        ..fieldPath = (FieldPath()..fieldName.addAll(fieldPath))
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


    Stream<E> observeEvents<E extends GeneratedMessage>(E prototype) {
        var subscription = EventSubscriptionRequest(_client, prototype)
            .where(all([eq(['context', 'past_message'], _commandAsOrigin())]))
            .post();
        _subscriptions.add(subscription);
        return subscription.eventMessages;
    }

    Origin _commandAsOrigin() {
        MessageId id = MessageId()
            ..id = pack(_command.id)
            ..typeUrl = _command.message.typeUrl;
        return Origin()
            ..message = id
            ..actorContext = _command.context.actorContext;
    }

    Stream<Event> observeEventsWithContexts(GeneratedMessage prototype) {
        var subscription = EventSubscriptionRequest(_client, prototype)
            .where(all([eq(['context', 'past_message'], _commandAsOrigin())]))
            .post();
        _subscriptions.add(subscription);
        return subscription.events;
    }

    Set<EventSubscription> post({CommandErrorCallback onError}) {
        if (_subscriptions.isNotEmpty) {
            throw StateError('Use `observeEvents(..)` or `observeEventsWithContexts(..)` to observe'
                ' command results or call `postAndForget()` instead of `post()` if you observe'
                ' command results elsewhere.');
        }
        _doPost(onError);
        return Set()..addAll(_subscriptions);
    }

    void postAndForget({CommandErrorCallback onError}) {
        if (_subscriptions.isNotEmpty) {
            throw StateError('Use `post()` to add event subscriptions.');
        }
        _doPost(onError);
    }

    void _doPost(CommandErrorCallback onError) {
        _client._postCommand(_command, onError);
    }
}

class QueryRequest<M extends GeneratedMessage> {

    QueryRequest<M> fields(List<String> field_paths) {

        return this;
    }

    QueryRequest<M> where(CompositeFilter filter) {
        return this;
    }

    QueryRequest<M> whereIds(List<Object> ids) {

        return this;
    }

    QueryRequest<M> orderBy(String column, OrderBy_Direction direction) {

        return this;
    }

    QueryRequest<M> limit(int count) {

        return this;
    }

    Stream<M> post() {

    }
}

class SubscriptionRequest<M extends GeneratedMessage> {

    SubscriptionRequest<M> where(CompositeFilter filter) {

        return this;
    }

    StateSubscription<M> post() {

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

typedef NetworkErrorCallback(Error error);
typedef CommandErrorCallback(pbError.Error error);
