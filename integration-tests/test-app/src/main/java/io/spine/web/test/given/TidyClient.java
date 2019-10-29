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

import com.google.firebase.database.ChildEventListener;
import io.spine.web.firebase.FirebaseClient;
import io.spine.web.firebase.NodePath;
import io.spine.web.firebase.NodeValue;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

import static com.google.common.base.Preconditions.checkNotNull;
import static java.util.Collections.synchronizedSet;

public class TidyClient implements FirebaseClient {

    private final Set<NodePath> writtenNodes = synchronizedSet(new HashSet<>());
    private final FirebaseClient delegate;

    public TidyClient(FirebaseClient delegate) {
        this.delegate = checkNotNull(delegate);
        Runtime.getRuntime()
               .addShutdownHook(new Thread(() -> writtenNodes.forEach(delegate::delete)));
    }

    @Override
    public Optional<NodeValue> fetchNode(NodePath nodePath) {
        return delegate.fetchNode(nodePath);
    }

    @Override
    public void subscribeTo(NodePath nodePath, ChildEventListener listener) {
        delegate.subscribeTo(nodePath, listener);
    }

    @Override
    public void create(NodePath nodePath, NodeValue value) {
        delegate.create(nodePath, value);
        writtenNodes.add(nodePath);
    }

    @Override
    public void update(NodePath nodePath, NodeValue value) {
        delegate.update(nodePath, value);
        writtenNodes.add(nodePath);
    }

    @Override
    public void delete(NodePath nodePath) {
        delegate.delete(nodePath);
        writtenNodes.remove(nodePath);
    }
}
