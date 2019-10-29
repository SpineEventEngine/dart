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

package io.spine.web.test.given;

import com.google.protobuf.Timestamp;
import io.spine.core.Subscribe;
import io.spine.core.UserId;
import io.spine.server.entity.storage.Column;
import io.spine.server.entity.storage.EntityColumn;
import io.spine.server.projection.Projection;

import java.util.List;

/**
 * A projection representing a user and a list of {@link TaskId tasks} assigned to him.
 *
 * <p>Assigned tasks count and indication of several tasks assigned are exposed as
 * {@link EntityColumn} allowing ordering and filtering when user tasks are queried.
 */
public class UserTasksProjection extends Projection<UserId, UserTasks, UserTasks.Builder> {

    protected UserTasksProjection(UserId id) {
        super(id);
    }

    @Subscribe
    void on(TaskCreated event) {
        builder().setId(event.getAssignee())
                 .addTasks(event.getId())
                 .setLastUpdated(event.getWhen());
    }

    // TODO 5/31/2019[yegor.udovchenko]: Remove @CheckReturnValue suppression
    // for `remove` operation
    @SuppressWarnings("CheckReturnValue")
    @Subscribe
    void on(TaskReassigned event) {
        if (reassignedFromThisUser(event)) {
            List<TaskId> tasks = state().getTasksList();
            final int reassigned = tasks.indexOf(event.getId());
            builder().removeTasks(reassigned);
        } else if (reassignedToThisUser(event)){
            builder().setId(event.getTo())
                     .addTasks(event.getId());
        }

        builder().setLastUpdated(event.getWhen());
    }

    @Column
    public int getTasksCount() {
        return state().getTasksCount();
    }

    @Column
    public boolean isOverloaded() {
        return state().getTasksCount() > 1;
    }

    @Column
    public Timestamp getLastUpdated() {
        return state().getLastUpdated();
    }

    private boolean reassignedFromThisUser(TaskReassigned event) {
        return event.hasFrom() && event.getFrom().equals(id());
    }

    private boolean reassignedToThisUser(TaskReassigned event) {
        return event.hasTo() && event.getTo().equals(id());
    }
}
