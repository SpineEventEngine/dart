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

import io.spine.internal.gradle.base.assemble
import io.spine.internal.gradle.base.clean
import io.spine.internal.gradle.base.check
import org.gradle.api.tasks.Delete
import org.gradle.api.tasks.Exec
import org.gradle.api.tasks.TaskContainer
import org.gradle.api.tasks.TaskProvider
import org.gradle.kotlin.dsl.named
import org.gradle.kotlin.dsl.register

/**
 * Registers tasks for building Dart projects.
 *
 * List of tasks to be created:
 *
 *  1. [TaskContainer.cleanPackageIndex];
 *  2. [TaskContainer.resolveDependencies];
 *  3. [TaskContainer.testDart].
 *
 * An example of how to apply it in `build.gradle.kts`:
 *
 * ```
 * import io.spine.internal.gradle.dart.dart
 * import io.spine.internal.gradle.dart.task.build
 *
 * // ...
 *
 * dart {
 *     tasks {
 *         build()
 *     }
 * }
 * ```
 *
 * @param configuration any additional configuration related to the module's building.
 */
fun DartTasks.build(configuration: DartTasks.() -> Unit) {

    cleanPackageIndex().also {
        clean.configure {
            dependsOn(it)
        }
    }

    resolveDependencies().also {
        assemble.configure {
            dependsOn(it)
        }
    }

    testDart().also {
        check.configure {
            dependsOn(it)
        }
    }

    configuration()
}


/**
 * Locates `resolveDependencies` task in this [TaskContainer].
 *
 * The task fetches dependencies declared via `pubspec.yaml` using `pub get` command.
 */
val TaskContainer.resolveDependencies: TaskProvider<Exec>
    get() = named<Exec>("resolveDependencies")

private fun DartTasks.resolveDependencies(): TaskProvider<Exec> =
    register<Exec>("resolveDependencies") {

        description = "Fetches dependencies declared via `pubspec.yaml`."
        group = dartBuildTask

        mustRunAfter(cleanPackageIndex)

        inputs.file(pubSpec)
        outputs.file(packageIndex)

        pub("get")
    }


/**
 * Locates `cleanPackageIndex` task in this [TaskContainer].
 *
 * The task deletes the resolved `.packages` and `package_config.json` files.
 *
 * A Dart package configuration file is used to resolve Dart package names to Dart files
 * containing the source code for that package.
 *
 * The standard package configuration file is `package_config.json`. For backwards compatability
 * `pub` still updates the deprecated `.packages` file. Hence, the task deletes both files.
 */
val TaskContainer.cleanPackageIndex: TaskProvider<Delete>
    get() = named<Delete>("cleanPackageIndex")

private fun DartTasks.cleanPackageIndex(): TaskProvider<Delete> =
    register<Delete>("cleanPackageIndex") {

        description = "Deletes the resolved `.packages` and `package_config.json` files."
        group = dartBuildTask

        delete(packageIndex, packageConfig)
    }


/**
 * Locates `testDart` task in this [TaskContainer].
 *
 * The task runs Dart tests declared in the `./test` directory.
 */
val TaskContainer.testDart: TaskProvider<Exec>
    get() = named<Exec>("testDart")

private fun DartTasks.testDart(): TaskProvider<Exec> =
    register<Exec>("testDart") {

        description = "Runs Dart tests declared in the `./test` directory."
        group = dartBuildTask

        dependsOn(resolveDependencies)

        pub("run", "test")
    }
