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

import 'package:spine_client/command_factory.dart';
import 'package:spine_client/query_factory.dart';
import 'package:spine_client/spine/core/actor_context.pb.dart';
import 'package:spine_client/spine/core/tenant_id.pb.dart';
import 'package:spine_client/spine/core/user_id.pb.dart';
import 'package:spine_client/spine/time/time.pb.dart';
import 'package:spine_client/time.dart' as time;

/// A factory for various requests fired from the client-side by an actor.
class ActorRequestFactory {

    final UserId actor;
    final TenantId tenant;
    final ZoneOffset zoneOffset;
    final ZoneId zoneId;

    /// Creates a new [ActorRequestFactory].
    ///
    /// An [actor] is the ID of a user who initiates the request. If there is no user ID
    /// (e.g. before the login) a conventional user ID should be used. Usually, `Anonymous` is
    /// chosen for the absent user ID.
    ///
    /// In multitenant systems, it's required for all the actor requests to have a [tenant] ID.
    ///
    ActorRequestFactory(this.actor, [this.tenant, this.zoneOffset, this.zoneId]);

    /// Creates a factory of queries to the server.
    QueryFactory query() {
        return QueryFactory(_context);
    }

    /// Creates a factory of commands to send to the server.
    CommandFactory command() {
        return CommandFactory(_context);
    }

    ActorContext _context() {
        var ctx = ActorContext();
        ctx
            ..actor = this.actor
            ..timestamp = time.now()
            ..tenantId = this.tenant ?? TenantId.getDefault()
            ..zoneOffset = zoneOffset ?? time.zoneOffset()
            ..zoneId = zoneId ?? time.guessZoneId();
        return ctx;
    }
}

/// A function which generates an [ActorContext].
typedef ActorContext ActorProvider();
