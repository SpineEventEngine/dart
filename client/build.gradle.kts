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

import java.nio.file.Files
import java.nio.file.Path
import com.google.protobuf.gradle.protobuf
import com.google.protobuf.gradle.testProtobuf
import io.spine.gradle.internal.Deps
import io.spine.internal.gradle.base.assemble
import io.spine.internal.gradle.dart.dart
import io.spine.internal.gradle.dart.task.build
import io.spine.internal.gradle.dart.task.publish
import io.spine.internal.gradle.dart.plugin.protobuf

plugins {
    java
    codegen
    dart
}

apply {
    from(Deps.scripts.javadocOptions(project))
    from(Deps.scripts.updateGitHubPages(project))
}

val spineBaseVersion: String by extra
val spineWebVersion: String by extra

dependencies {
    protobuf("io.spine.gcloud:spine-firebase-web:$spineWebVersion")

    // Until https://github.com/dart-lang/protobuf/issues/295 is
    // resolved, all types must be compiled in a single batch.

    testProtobuf("io.spine:spine-base:$spineBaseVersion")
    testProtobuf("io.spine.tools:spine-tool-base:$spineBaseVersion")
}

dart {
    plugins {
        protobuf()
    }
    tasks {
        build {
            assemble { dependsOn("generateDart", "generateTestDart") }
        }
        publish()
    }
}

tasks {
    val dartDocDir: Path = Files.createTempDirectory("dartDocDir")
    val dartDoc by registering(Exec::class) {
        commandLine("dartdoc", "--output", dartDocDir, "$projectDir/lib/")
    }

    afterEvaluate {
        extra["generatedDocs"] = files(dartDocDir)
        tasks["updateGitHubPages"].dependsOn(dartDoc)
        tasks["publish"].dependsOn("updateGitHubPages")
    }
}
