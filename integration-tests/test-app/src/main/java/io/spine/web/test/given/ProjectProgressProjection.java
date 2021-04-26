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

package io.spine.web.test.given;

import io.spine.core.Subscribe;
import io.spine.server.projection.Projection;
import io.spine.server.entity.storage.Column;

import static io.spine.web.test.given.Status.COMPLETED;
import static io.spine.web.test.given.Status.IN_PROGRESS;
import static io.spine.web.test.given.Status.NOT_STARTED;

/**
 * A projection representing a progress of tasks completion within a project.
 *
 * <p>Calculates the amount of the completed and uncompleted tasks. Upon completion of all tasks,
 * switches the project progress status to the {@code COMPLETED}. Current status is exposed as
 * {@linkplain Column column} allowing filtering of completed and uncompleted progresses.
 */
public class ProjectProgressProjection
        extends Projection<ProjectId, ProjectProgress, ProjectProgress.Builder> {

    @Subscribe
    void on(ProjectCreated event) {
        builder().setTotalTasks(0)
                 .setCompletedTasks(0)
                 .setStatus(NOT_STARTED);
    }

    @Subscribe
    void on(TaskCreated event) {
        int totalTasks = state().getTotalTasks() + 1;
        builder().setTotalTasks(totalTasks)
                 .setStatus(IN_PROGRESS);
    }

    @Subscribe
    void on(TaskCompleted event) {
        int completedTasks = state().getCompletedTasks() + 1;
        builder().setCompletedTasks(completedTasks)
                 .setStatus(calculateStatus(completedTasks));
    }

    private Status calculateStatus(int completedTasks) {
        if (completedTasks == state().getTotalTasks()) {
            return COMPLETED;
        } else {
            return IN_PROGRESS;
        }
    }
}
