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

import com.google.common.io.Files
import com.google.protobuf.gradle.builtins
import com.google.protobuf.gradle.generateProtoTasks
import com.google.protobuf.gradle.id
import com.google.protobuf.gradle.plugins
import com.google.protobuf.gradle.protobuf
import com.google.protobuf.gradle.remove
import com.google.protobuf.gradle.testProtobuf
import io.spine.gradle.internal.Deps
import io.spine.internal.gradle.dart.dart
import io.spine.internal.gradle.dart.task.registerBuildTasks
import io.spine.internal.gradle.dart.task.registerPublishTasks

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

    // TODO:2019-10-25:dmytro.dashenkov: Until https://github.com/dart-lang/protobuf/issues/295 is
    //  resolved, all types must be compiled in a single batch.

    testProtobuf("io.spine:spine-base:$spineBaseVersion")
    testProtobuf("io.spine.tools:spine-tool-base:$spineBaseVersion")
}

dart {
    tasks {
        registerBuildTasks()
        registerPublishTasks()

//        it is read as "two task are going to be registered".
//
//        register {
//            build()
//            publish()
//        }
//
//
//        it is read as "two groups of task are going to be registered".
//        and it is our objective.
//
//        register {
//            buildTasks()
//            publishTasks()
//        }
//
//        registerGroup {
//            build()
//            publish()
//        }
//
//        register {
//            group {
//                build()
//                publish()
//            }
//        }
    }
}

tasks.assemble {
    dependsOn("generateDart", "generateTestDart")
}

val dartDocDir = Files.createTempDir()

val dartDoc by tasks.creating(Exec::class) {
    commandLine("dartdoc", "--output", dartDocDir.path, "$projectDir/lib/")
}

afterEvaluate {
    extra["generatedDocs"] = files(dartDocDir)
    tasks["updateGitHubPages"].dependsOn(dartDoc)
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
