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
 * Context for setting up Dart-related tasks.
 *
 * The context provides access to the current [DartEnvironment].
 *
 * Also, it is still possible to register and configure tasks on the top of this context,
 * it is highly recommended using the corresponding sub-contexts for that:
 *
 * ```
 * import io.spine.internal.gradle.dart.dart
 *
 * // ...
 *
 * // instead of using top level context:
 *
 * dart {
 *     tasks {
 *         withType<CompileDart> {
 *             version = "1.0"
 *         }
 *        registerNewTask()
 *     }
 * }
 *
 * // use the associated sub-contexts:
 *
 * dart {
 *     tasks {
 *         configure {
 *             withType<CompileDart> {
 *                 version = "1.0"
 *             }
 *         }
 *         register {
 *             newTask()
 *         }
 *     }
 * }
 * ```
 */
open class DartTasks(dartEnv: DartEnvironment, private val tasks: TaskContainer)
    : DartEnvironment by dartEnv, TaskContainer by tasks
{
    private val registering = DartTaskRegistering(dartEnv, tasks)
    private val configuring = DartTaskConfiguring(dartEnv, tasks)

    // Task groups.
    internal val dartBuildTask = "Dart/Build"
    internal val dartPublishTask = "Dart/Publish"

    /**
     * Registers new tasks.
     */
    fun register(registrations: DartTaskRegistering.() -> Unit) = registering.run(registrations)

    /**
     * Configures already registered tasks.
     */
    fun configure(configurations: DartTaskConfiguring.() -> Unit) = configuring.run(configurations)
}

/**
 * Context for registering Dart-related tasks.
 */
class DartTaskRegistering(dartEnv: DartEnvironment, tasks: TaskContainer)
    : DartTasks(dartEnv, tasks)

/**
 * Context for configuring Dart-related tasks.
 */
class DartTaskConfiguring(dartEnv: DartEnvironment, tasks: TaskContainer)
    : DartTasks(dartEnv, tasks)
