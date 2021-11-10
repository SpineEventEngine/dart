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

import org.gradle.api.Task
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.Exec
import org.gradle.kotlin.dsl.create

/**
 * Registers tasks for publishing Dart projects.
 *
 * List of tasks to be created:
 *
 *  1. `stagePubPublication` - prepares the Dart package for Pub publication;
 *  2. `publishToPub` - publishes the prepared publication to Pub;
 *  3. `activateLocally` - activates this package locally.
 *
 * Usage example:
 *
 * ```
 * import io.spine.internal.gradle.dart.dart
 *
 * // ...
 *
 * dart {
 *     tasks {
 *         register {
 *             publish()
 *         }
 *     }
 * }
 * ```
 */
fun DartTaskRegistering.publish() {

    val stagePubPublication = stagePubPublication().apply {
        dependsOn(getByName("assemble"))
    }

    publishToPub().apply {
        dependsOn(stagePubPublication)
        getByName("publish").dependsOn(this)
    }

    activateLocally().apply {
        dependsOn(stagePubPublication)
    }
}

private fun DartTaskRegistering.stagePubPublication(): Task =
    create<Copy>("stagePubPublication") {
        description = "Prepares the Dart package for Pub publication."
        group = dartPublishTask

        // Besides .dart files itself, `pub` package manager conventions require presence:

        // 1. README.md and CHANGELOG.md to build a page at `pub.dev/packages/<your_package>;
        // 2. The pubspec to fill out details about your package on the right side
        //    of your package’s page;
        // 3. LICENSE file.

        from(project.projectDir) {
            include("**/*.dart", "pubspec.yaml", "**/*.md")
            exclude("proto/", "generated/", "build/", "**/.*")
        }
        from("${project.rootDir}/LICENSE")
        into(publicationDirectory)

        doLast {
            logger.debug("Pub publication is prepared in directory `$publicationDirectory`.")
        }
    }

private fun DartTaskRegistering.publishToPub(): Task =
    create<Exec>("publishToPub") {
        description = "Publishes the prepared publication to Pub."
        group = dartPublishTask

        workingDir(publicationDirectory)
        commandLine(pubExecutable, "publish", "--trace")

        val sayYes = "y".byteInputStream()
        standardInput = sayYes
    }

/**
 * Makes this package available in the command line as an executable.
 *
 * The `dart run` command supports running a Dart program — located in a file, in the current
 * package, or in one of the dependencies of the current package - from the command line.
 * To run a program from an arbitrary location, the package should be "activated".
 *
 * See [dart pub global | Dart](https://dart.dev/tools/pub/cmd/pub-global)
 */
private fun DartTaskRegistering.activateLocally(): Task =
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
