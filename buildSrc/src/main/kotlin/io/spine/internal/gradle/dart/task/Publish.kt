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

import io.spine.internal.gradle.dart.DartTasks
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.Exec
import org.gradle.kotlin.dsl.create
import org.gradle.kotlin.dsl.get
import org.gradle.kotlin.dsl.getByType

fun Project.registerPublishTasks() {

    extensions.getByType<DartTasks>().run {

        val stagePubPublication = stagePubPublication().apply {
            dependsOn(getByName("assemble"))
        }

        publishToPub().apply {
            dependsOn(stagePubPublication)
            tasks["publish"].dependsOn(this)
        }

        activateLocally().apply {
            dependsOn(stagePubPublication)
        }
    }
}

private fun DartTasks.stagePubPublication(): Task =
    create<Copy>("stagePubPublication") {
        description = "Prepares the Dart package for Pub publication."
        group = dartPublishTask

        from(project.projectDir) {
            include("**/*.dart", "pubspec.yaml", "**/*.md")
            exclude("proto/", "generated/", "build/", "**/.*")
        }
        from("${project.rootDir}/LICENSE")
        into(publicationDirectory)

        doLast {
            logger.debug("Prepared Pub publication in directory `$publicationDirectory`.")
        }
    }

private fun DartTasks.publishToPub(): Task =
    create<Exec>("publishToPub") {
        description = "Published this package to Pub."
        group = dartPublishTask

        workingDir(publicationDirectory)
        commandLine(pubExecutable, "publish", "--trace")

        val sayYes = "y".byteInputStream()
        standardInput = sayYes
    }

private fun DartTasks.activateLocally(): Task =
    create<Exec>("activateLocally") {
        description = "Activates this package locally."
        group = dartPublishTask

        workingDir(publicationDirectory)
        commandLine(
            pubExecutable,
            "global",
            "activate",
            "--source",
            "path",
            publicationDirectory,
            "--trace"
        )
    }
