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
 * Provides a scope for all Dart-related configuration.
 *
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
 * Gradle's extension for Dart-related configuration.
 */
open class DartExtension(project: Project) {

    /**
     * Default values for [DartEnvironment] based on Dart conventions.
     */
    val defaultEnvironment = object : DartEnvironment {

        override val publicationDirectory = "${project.buildDir}/pub/publication/${project.name}"
        override val pubExecutable = "pub${if (Os.isFamily(Os.FAMILY_WINDOWS)) ".bat" else ""}"
        override val pubSpec = "${project.projectDir}/pubspec.yaml"
        override val packageIndex = "${project.projectDir}/.packages"
        override val packageConfig = "${project.projectDir}/.dart_tool/package_config.json"
    }

    private val environment = ConfigurableDartEnvironment(defaultEnvironment)
    private val tasks = DartTasks(environment, project.tasks)

    /**
     * Overriding default values of [DartEnvironment].
     *
     * Please note, environment should be configured firstly to have the effect on the parts
     * of the extension that depend on it.
     */
    fun environment(configuration: ConfigurableDartEnvironment.() -> Unit) =
        configuration.invoke(environment)

    /**
     * Configures [dart tasks][DartTasks] container.
     */
    fun tasks(configuration: DartTasks.() -> Unit) =
        configuration.invoke(tasks)
}
