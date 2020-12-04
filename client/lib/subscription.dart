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

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/firebase_client.dart';
import 'package:spine_client/spine/client/subscription.pb.dart' as pb;
import 'package:spine_client/spine/core/event.pb.dart';
import 'package:spine_client/spine/web/firebase/subscription/firebase_subscription.pb.dart';
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/src/json.dart';

class Subscription<T extends GeneratedMessage> {

    final Future<pb.Subscription> subscription;

    final Stream<T> _itemAdded;

    bool _closed;

    Subscription(this.subscription, Stream<T> itemAdded)
        : _itemAdded = _checkIsBroadCast(itemAdded),
          _closed = false;

    bool get closed => _closed;

    /// Closes this subscription.
    ///
    /// The server will stop reflecting the updates for the topic.
    ///
    void unsubscribe() {
        _closed = true;
    }
}

/// A subscription for event or entity changes.
///
/// The [itemAdded], [itemChanged] and [itemRemoved] streams reflect the changes of a corresponding
/// event/entity type. The streams are broadcast ([Stream.isBroadcast]]), i.e. can have any number
/// of listeners simultaneously.
///
/// To stop receiving updates from the server, invoke [unsubscribe]. This will cancel the
/// subscription both on the client and on the server, stopping the changes from being reflected to
/// Firebase.
///
class StateSubscription<T extends GeneratedMessage> extends Subscription<T> {

    final Stream<T> itemChanged;
    final Stream<T> itemRemoved;

    Stream<T> get itemAdded => _itemAdded;

    bool _closed;

    StateSubscription._(Future<pb.Subscription> subscription,
                        Stream<T> itemAdded,
                        Stream<T> itemChanged,
                        Stream<T> itemRemoved):
            itemChanged = _checkIsBroadCast(itemChanged),
            itemRemoved = _checkIsBroadCast(itemRemoved),
            _closed = false,
            super(subscription, itemAdded);

    /// Creates a new instance which broadcasts updates from under the given Firebase node.
    factory StateSubscription.of(Future<FirebaseSubscription> firebaseSubscription,
                                 BuilderInfo builderInfoForType,
                                 FirebaseClient database) {
        var subscription = firebaseSubscription.then((value) => value.subscription);
        var nodePath = firebaseSubscription
            .then((value) => value.nodePath.value)
            .asStream();
        var itemAdded = nodePath
            .asyncExpand((element) => database.childAdded(element))
            .map((json) => parseIntoNewInstance<T>(builderInfoForType, json));
        var itemChanged = nodePath
            .asyncExpand((element) => database.childChanged(element))
            .map((json) => parseIntoNewInstance<T>(builderInfoForType, json));
        var itemRemoved = nodePath
            .asyncExpand((element) => database.childChanged(element))
            .map((json) => parseIntoNewInstance<T>(builderInfoForType, json));
        return StateSubscription._(subscription, itemAdded, itemChanged, itemRemoved);
    }
}

class EventSubscription<T extends GeneratedMessage> extends Subscription<Event> {

    static final BuilderInfo _eventBuilderInfo = Event.getDefault().info_;

    EventSubscription._(Future<pb.Subscription> subscription, Stream<Event> itemAdded) :
            super(subscription, itemAdded);

    factory EventSubscription.of(Future<FirebaseSubscription> firebaseSubscription,
                                 FirebaseClient database) {
        var subscription = firebaseSubscription.then((value) => value.subscription);
        var itemAdded = firebaseSubscription
            .then((value) => value.nodePath.value)
            .asStream()
            .asyncExpand((path) => database.childAdded(path))
            .map((json) => parseIntoNewInstance<Event>(_eventBuilderInfo, json));
        return EventSubscription._(subscription, itemAdded);
    }

    Stream<Event> get events => _itemAdded;

    Stream<T> get eventMessages => events
        .map((event) => unpack(event.message));
}

Stream<T> _checkIsBroadCast<T>(Stream<T> stream) {
    if (!stream.isBroadcast) {
        throw ArgumentError(
            'All streams passed to an `Subscription` instance should be broadcast.'
        );
    }
    return stream;
}
