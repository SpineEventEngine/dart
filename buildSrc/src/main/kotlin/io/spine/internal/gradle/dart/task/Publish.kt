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

import org.apache.tools.ant.taskdefs.condition.Os
import org.gradle.api.Project
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.Exec
import org.gradle.kotlin.dsl.get
import org.gradle.kotlin.dsl.register

private val extension = if (Os.isFamily(Os.FAMILY_WINDOWS)) ".bat" else ""
private val PUB_EXECUTABLE = "pub$extension"

fun Project.registerPublishTasks() {
    val PUBLICATION_DIR = "$buildDir/pub/publication/$project.name"

    val stagePubPublication = tasks.register<Copy>("stagePubPublication") {
        description = "Prepares the Dart package for Pub publication."

        from(
            fileTree(projectDir) {
                include("**/*.dart", "pubspec.yaml", "**/*.md")
                exclude("proto/", "generated/", "build/", "**/.*")
            },
            "$rootDir/LICENSE"
        )
        into(PUBLICATION_DIR)

        doLast {
            logger.debug("Prepared Pub publication in directory `$PUBLICATION_DIR`.")
        }

        dependsOn("assemble")
    }

    val publishToPub = tasks.register<Exec>("publishToPub") {
        description = "Published this package to Pub."

        workingDir(PUBLICATION_DIR)
        commandLine(PUB_EXECUTABLE, "publish", "--trace")

        val sayYes = "y".byteInputStream()
        standardInput = sayYes

        dependsOn(stagePubPublication)
    }

    tasks.register<Exec>("activateLocally") {
        description = "Activates this package locally."

        workingDir(PUBLICATION_DIR)
        commandLine(
            PUB_EXECUTABLE,
            "global",
            "activate",
            "--source",
            "path",
            PUBLICATION_DIR,
            "--trace"
        )

        dependsOn(stagePubPublication)
    }

    tasks["publish"].dependsOn(publishToPub)
}
