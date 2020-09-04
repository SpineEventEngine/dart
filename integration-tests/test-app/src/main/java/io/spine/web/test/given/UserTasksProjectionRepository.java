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

package io.spine.web.test.given;

import com.google.common.collect.ImmutableSet;
import com.google.errorprone.annotations.OverridingMethodsMustInvokeSuper;
import io.spine.core.UserId;
import io.spine.server.projection.ProjectionRepository;
import io.spine.server.route.EventRouting;

import static io.spine.server.route.EventRoute.noTargets;
import static io.spine.server.route.EventRoute.withId;

/**
 * A repository for the user tasks projections.
 */
public class UserTasksProjectionRepository extends ProjectionRepository<UserId, UserTasksProjection, UserTasks> {

    /**
     * Sets up the event routing for all the types of events handled by {@link UserTasksProjection}.
     */
    @OverridingMethodsMustInvokeSuper
    @Override
    protected void setupEventRouting(EventRouting<UserId> routing) {
        routing.route(TaskCreated.class, (e, ctx) -> e.hasAssignee()
                                                     ? withId(e.getAssignee())
                                                     : noTargets())
               .route(TaskReassigned.class, (e, ctx) -> e.hasFrom()
                                                        ? ImmutableSet.of(e.getFrom(),
                                                                          e.getTo())
                                                        : withId(e.getTo()));
        super.setupEventRouting(routing);
    }
}
