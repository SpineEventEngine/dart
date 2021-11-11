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

package io.spine.internal.gradle.dart.task

import io.spine.internal.gradle.dart.DartEnvironment
import org.gradle.api.tasks.TaskContainer

/**
 * Scope for setting up Dart-related tasks.
 *
 * Within this scope new tasks can be registered and already present tasks configured.
 *
 * An example of a present task configuration:
 *
 * ```
 * fun DartTaskConfiguring.dartCompile() { ... }
 *
 * tasks {
 *     configure {
 *         dartCompile()
 *      }
 * }
 * ```
 *
 * An example of a new task registration:
 *
 * ```
 * fun DartTaskRegistering.customDartCompile() { ... }
 *
 * tasks {
 *     register {
 *         customDartCompile()
 *     }
 * }
 * ```
 *
 * @see DartTaskConfiguring
 * @see DartTaskRegistering
 */
open class DartTasks(dartEnv: DartEnvironment, tasks: TaskContainer)
    : DartTasksContext(dartEnv, tasks)
{
    private val registering = DartTaskRegistering(dartEnv, tasks)
    private val configuring = DartTaskConfiguring(dartEnv, tasks)

    /**
     * Registers new tasks.
     */
    fun register(registrations: DartTaskRegistering.() -> Unit) =
        registering.run(registrations)

    /**
     * Configures already registered tasks.
     */
    fun configure(configurations: DartTaskConfiguring.() -> Unit) =
        configuring.run(configurations)
}

/**
 * Context for setting up Dart-related tasks.
 *
 * Exposes the current [DartEnvironment] and defines the default task groups.
 */
open class DartTasksContext(dartEnv: DartEnvironment, tasks: TaskContainer)
    : DartEnvironment by dartEnv, TaskContainer by tasks
{
    internal val dartBuildTask = "Dart/Build"
    internal val dartPublishTask = "Dart/Publish"
}

/**
 * Scope for registering new tasks inside [DartTasksContext].
 */
class DartTaskRegistering(dartEnv: DartEnvironment, tasks: TaskContainer)
    : DartTasksContext(dartEnv, tasks)

/**
 * Scope for configuring present tasks inside [DartTasksContext].
 */
class DartTaskConfiguring(dartEnv: DartEnvironment, tasks: TaskContainer)
    : DartTasksContext(dartEnv, tasks)
