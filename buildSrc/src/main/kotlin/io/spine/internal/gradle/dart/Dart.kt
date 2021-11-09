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

import org.apache.tools.ant.taskdefs.condition.Os
import org.gradle.api.Project
import org.gradle.api.tasks.TaskContainer
import org.gradle.kotlin.dsl.create
import org.gradle.kotlin.dsl.findByType

/**
 * Defines the scope for Dart related configuration.
 *
 * Configuration is performed through [DartExtension].
 */
fun Project.dart(configuration: DartExtension.() -> Unit) {
    extensions.run {
        configuration.invoke(
            findByType() ?: create("dartExtension", project)
        )
    }
}

/**
 * Encapsulates Dart related configuration.
 */
open class DartExtension(project: Project) {

    private val defaultEnv = object : DartEnvironment {
        override val pubExecutable = "pub${if (Os.isFamily(Os.FAMILY_WINDOWS)) ".bat" else ""}"
        override val packageIndex = "${project.projectDir}/.packages"
        override val pubSpec = "${project.projectDir}/pubspec.yaml"
        override val publicationDirectory = "${project.buildDir}/pub/publication/${project.name}"
    }

    @Suppress("LeakingThis")
    private val tasks = DartTasks(defaultEnv, project.tasks)

    fun tasks(configuration: DartTasks.() -> Unit) = configuration.invoke(tasks)
}

/**
 * Information about Dart environment.
 */
interface DartEnvironment {

    /**
     * Path to a directory for local publications of a `Pub` package for this project.
     */
    val publicationDirectory: String

    /**
     * Path to a `Pub` package manager executable.
     */
    val pubExecutable: String

    /**
     * Path to `pubspec.yaml` file.
     */
    val pubSpec: String

    /**
     * Path to `.packages` file.
     */
    val packageIndex: String
}

/**
 * Context for assembling Dart related tasks with access to the current [DartEnvironment].
 */
class DartTasks(dartEnv: DartEnvironment, tasks: TaskContainer)
    : DartEnvironment by dartEnv, TaskContainer by tasks
{
    val dartBuildTask = "Dart/Build"
    val dartPublishTask = "Dart/Publish"
}
