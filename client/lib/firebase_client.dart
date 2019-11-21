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

/// A client of a Firebase Realtime Database.
///
/// This class is a platform-agnostic interface. Implementations are platform-specific.
///
abstract class FirebaseClient {

    /// Obtains children of the database node under a given path.
    ///
    /// If the node values are strings, those strings are obtained without change. Otherwise,
    /// the values are converted into JSONs in form of strings and yielded.
    ///
    /// It is expected that the implementations are asynchronous and do not block the calling site
    /// for a long time (i.e. while performing networking).
    ///
    Stream<String> get(String path);

    /// Obtains the "childAdded" event stream of the node under a given path.
    ///
    /// The "childAdded" event is triggered once for each existing child and then again every time
    /// a new child is added to the specified path.
    ///
    /// The resulting stream contains the new values serialized to JSON by similar rules to [get].
    ///
    Stream<String> childAdded(String path);

    /// Obtains the "childChanged" event stream of the node under a given path.
    ///
    /// The "childChanged" event is triggered any time a child node is modified. This includes any
    /// modifications to descendants of the child node.
    ///
    /// The resulting stream contains the changed values serialized to JSON by similar rules
    /// to [get].
    ///
    Stream<String> childChanged(String path);

    /// Obtains the "childRemoved" event stream of the node under a given path.
    ///
    /// The "childRemoved" event is triggered when an immediate child is removed.
    ///
    /// The resulting stream contains the removed values serialized to JSON by similar rules
    /// to [get].
    ///
    Stream<String> childRemoved(String path);
}
