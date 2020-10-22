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
import 'package:spine_client/actor_request_factory.dart';
import 'package:spine_client/spine/client/query.pb.dart';
import 'package:spine_client/target_builder.dart';
import 'package:spine_client/uuids.dart';

/// A factory of queries to the server.
class QueryFactory {

    final ActorProvider _context;

    QueryFactory(this._context);

    /// Creates a query which matches all entities of the given type with the given IDs.
    Query byIds(GeneratedMessage instance, List<Object> ids) {
        var query = Query();
        query
            ..id = _newId()
            ..target = targetByIds(instance, ids)
            ..context = _context();
        return query;
    }

    /// Creates a query which matches all entities of the given type.
    Query all(GeneratedMessage instance) {
        var query = Query();
        query
            ..id = _newId()
            ..target = targetAll(instance)
            ..context = _context();
        return query;
    }

    QueryId _newId() {
        var id = QueryId();
        id.value = newUuid(prefix: 'q-');
        return id;
    }
}
