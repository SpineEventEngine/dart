/*
 * Copyright 2020, TeamDev. All rights reserved.
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

import com.google.common.io.Files
import com.google.protobuf.gradle.*
import io.spine.gradle.internal.Deps

plugins {
    java
    codegen
    dart
}

apply {
    from(Deps.scripts.dartBuildTasks(project))
    from(Deps.scripts.pubPublishTasks(project))
    from(Deps.scripts.javadocOptions(project))
    from(Deps.scripts.updateGitHubPages(project))
}

val spineWebVersion: String by extra

dependencies {
    protobuf("io.spine.gcloud:spine-firebase-web:$spineWebVersion")
}

tasks.assemble {
    dependsOn("generateDart")
}

val dartDocDir = Files.createTempDir()

val dartDoc by tasks.creating(Exec::class) {
    commandLine("dartdoc", "--output", dartDocDir.path, "$projectDir/lib/")
}

afterEvaluate {
    extra["generatedDocs"] = files(dartDocDir)
    tasks["updateGitHubPages"].dependsOn("dartDoc")
    tasks["publish"].dependsOn("updateGitHubPages")
}

protobuf {
    generateProtoTasks {
        all().forEach { task ->
            task.plugins {
                id("dart")
            }
            task.builtins {
                remove("java")
            }
        }
    }
}
