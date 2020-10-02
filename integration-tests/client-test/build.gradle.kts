/*
 * Copyright 2019, TeamDev. All rights reserved.
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

import com.google.protobuf.gradle.*
import io.spine.gradle.internal.Deps
import org.apache.tools.ant.taskdefs.condition.Os

plugins {
    codegen
    dart
    id("io.spine.tools.proto-dart-plugin")
}

apply {
    from(Deps.scripts.dartBuildTasks(project))
}


dependencies {
    testProtobuf(project(":test-app"))
}

tasks["testDart"].enabled = false

val integrationTestDir = "./integration-test"

val integrationTest by tasks.creating(Exec::class) {
    val pub = "pub" + if (Os.isFamily(Os.FAMILY_WINDOWS)) ".bat" else ""

    // Run tests in Chrome browser because they use a `WebFirebaseClient` which only works in web
    // environment.
    commandLine(pub, "run", "test", integrationTestDir, "-p", "chrome")

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
