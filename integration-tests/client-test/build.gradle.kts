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

import com.google.protobuf.gradle.builtins
import com.google.protobuf.gradle.generateProtoTasks
import com.google.protobuf.gradle.id
import com.google.protobuf.gradle.plugins
import com.google.protobuf.gradle.protobuf
import com.google.protobuf.gradle.remove
import com.google.protobuf.gradle.testProtobuf
import io.spine.gradle.internal.Deps
import org.apache.tools.ant.taskdefs.condition.Os

plugins {
    codegen
    dart
    id("io.spine.tools.proto-dart-plugin")}

apply {
    from(Deps.scripts.dartBuildTasks(project))
}

dependencies {
    testProtobuf(project(":test-app"))
}

tasks["testDart"].enabled = false

val integrationTestDir = "./integration-test"

val integrationTest by tasks.creating(Exec::class) {
    // Run tests in Chrome browser because they use a `WebFirebaseClient` which only works in web
    // environment.
    commandLine("dart", "pub", "run", "test", integrationTestDir, "-p", "chrome")

    dependsOn("resolveDependencies", ":test-app:appBeforeIntegrationTest")
    finalizedBy(":test-app:appAfterIntegrationTest")
}

protoDart {
    testDir.set(project.layout.projectDirectory.dir(integrationTestDir))
}

tasks.generateDart {
    descriptor = protoDart.testDescriptorSet
    target = "$projectDir/integration-test"
}

tasks.assemble {
    dependsOn("generateDart")
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
