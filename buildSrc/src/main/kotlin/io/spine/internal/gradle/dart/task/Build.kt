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
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.tasks.Delete
import org.gradle.api.tasks.Exec
import org.gradle.kotlin.dsl.create
import org.gradle.kotlin.dsl.getByType

fun Project.registerBuildTasks() {

    extensions.getByType<DartEnvironment>().run {

        val resolveDependencies = resolveDependencies().also {
            getByName("assemble").dependsOn(it)
        }

        cleanPackageIndex().also {
            resolveDependencies.mustRunAfter(it)
            getByName("clean").dependsOn(it)
        }

        testDart().apply {
            dependsOn(resolveDependencies)
            getByName("check").dependsOn(this)
        }
    }
}

private fun DartEnvironment.cleanPackageIndex(): Task =
    create<Delete>("cleanPackageIndex") {
        description = "Deletes the `.packages` file on this Dart module."
        group = dartBuildTask

        setDelete(packageIndex)
    }

private fun DartEnvironment.resolveDependencies(): Task =
    create<Exec>("resolveDependencies") {
        description = "Fetches the dependencies declared via `pubspec.yaml`."
        group = dartBuildTask

        inputs.file(pubSpec)
        outputs.file(packageIndex)

        commandLine(pubExecutable, "get")
    }

private fun DartEnvironment.testDart(): Task =
    create<Exec>("testDart") {
        description = "Runs Dart tests declared in the `./test` directory. " +
                "See `https://pub.dev/packages/test#running-tests`."
        group = dartBuildTask

        commandLine(pubExecutable, "run", "test")
    }