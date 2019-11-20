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

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/firebase_client.dart';
import 'package:spine_client/spine/client/subscription.pb.dart';
import 'package:spine_client/spine/web/firebase/subscription/firebase_subscription.pb.dart';
import 'package:spine_client/src/json.dart';
import 'package:spine_client/src/known_types.dart';

class EntitySubscription<T extends GeneratedMessage> {

    final Subscription subscription;

    final Stream<T> itemAdded;
    final Stream<T> itemChanged;
    final Stream<T> itemRemoved;

    bool closed;

    EntitySubscription(this.subscription, this.itemAdded, this.itemChanged, this.itemRemoved);

    factory EntitySubscription.of(FirebaseSubscription firebaseSubscription,
                                  FirebaseClient database) {
        var subscription = firebaseSubscription.subscription;
        var typeUrl = subscription.topic.target.type;
        var builderInfo = theKnownTypes.findBuilderInfo(typeUrl);
        if (builderInfo == null) {
            throw ArgumentError.value(firebaseSubscription, 'firebase subscription',
                                      'Firebase subscription type `${typeUrl} is unknown.');
        }
        var nodePath = firebaseSubscription.nodePath.value;

        var itemAdded = database
            .childAdded(nodePath)
            .map((json) => parseIntoNewInstance(builderInfo, json));
        var itemChanged = database
            .childChanged(nodePath)
            .map((json) => parseIntoNewInstance(builderInfo, json));
        var itemRemoved = database
            .childRemoved(nodePath)
            .map((json) => parseIntoNewInstance(builderInfo, json));

        return new EntitySubscription(subscription, itemAdded, itemChanged, itemRemoved);
    }

    void unsubscribe() {
        closed = true;
    }
}
