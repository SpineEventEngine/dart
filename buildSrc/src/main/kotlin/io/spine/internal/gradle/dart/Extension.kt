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

package io.spine.internal.gradle.dart

import io.spine.internal.gradle.dart.task.DartTasks
import org.apache.tools.ant.taskdefs.condition.Os
import org.gradle.api.Project
import org.gradle.kotlin.dsl.create
import org.gradle.kotlin.dsl.findByType

/**
 * Configures [DartExtension].
 */
fun Project.dart(configuration: DartExtension.() -> Unit) {
    extensions.run {
        configuration.invoke(
            findByType() ?: create("dartExtension", project)
        )
    }
}

/**
 * Scope for performing Dart-related configuration.
 *
 * Here is the listing of available aspects to configure:
 *
 *  1. Environment - [MutableDartEnvironment];
 *  2. Tasks - [DartTasks].
 *
 * ### Environment
 *
 * The scope is shipped with the [default values][DartExtension.defaultEnvironment]
 * for [DartEnvironment] based on Dart conventions. Those values can be overwritten
 * through the [DartExtension.environment].
 *
 * An example of overwriting the default Dart environment value:
 *
 * ```
 * dart {
 *     environment {
 *         publicationDirectory = "${defaultEnvironment.publicationDirectory}_DRY_RUN"
 *     }
 * }
 * ```
 *
 * ### Tasks
 *
 * The scope provides its own [task container][DartTasks] within which all Dart-related tasks
 * should be registered and configured.
 *
 * ```
 * dart {
 *     tasks {
 *         ...
 *     }
 * }
 * ```
 */
open class DartExtension(project: Project) {

    private val defaultEnvironment = object : DartEnvironment {

        override val publicationDirectory = "${project.buildDir}/pub/publication/${project.name}"
        override val pubExecutable = "pub${if (Os.isFamily(Os.FAMILY_WINDOWS)) ".bat" else ""}"
        override val pubSpec = "${project.projectDir}/pubspec.yaml"
        override val packageIndex = "${project.projectDir}/.packages"
        override val packageConfig = "${project.projectDir}/.dart_tool/package_config.json"
    }

    private val environment = MutableDartEnvironment(defaultEnvironment)
    private val tasks = DartTasks(environment, project.tasks)

    /**
     * Overrides default values of [DartEnvironment].
     *
     * Please note, environment should be set up firstly to have the effect on the parts
     * of the extension that depend on it.
     */
    fun environment(overridings: MutableDartEnvironment.() -> Unit) = environment.run(overridings)

    /**
     * Configures [Dart-related tasks][DartTasks].
     */
    fun tasks(configurations: DartTasks.() -> Unit) = tasks.run(configurations)
}
