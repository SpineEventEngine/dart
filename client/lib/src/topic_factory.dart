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

import 'package:spine_client/spine/client/filters.pb.dart';
import 'package:spine_client/spine/client/subscription.pb.dart';
import 'package:spine_client/src/actor_request_factory.dart';
import 'package:spine_client/src/target_builder.dart';
import 'package:spine_client/uuids.dart';

/// A factory of [Topic] instances.
class TopicFactory {

    final ActorProvider _context;

    TopicFactory(this._context);

    /// Creates a topic which matches entities of the given type, IDs, and field values.
    Topic withFilters(Type type,
                      {Iterable<Object> ids = const [],
                       Iterable<CompositeFilter> filters = const []}) {
        var topic = Topic();
        topic
            ..id = _newId()
            ..target = target(type, ids: ids, fieldFilters: filters)
            ..context = _context();
        return topic;
    }

    TopicId _newId() {
        var id = TopicId();
        id.value = newUuid(prefix: 't-');
        return id;
    }
}
