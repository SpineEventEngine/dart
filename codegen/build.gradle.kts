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

plugins {
    codegen
    dart
    id("io.spine.tools.proto-dart-plugin")
}

apply {
    from(Deps.scripts.dartBuildTasks(project))
    from(Deps.scripts.pubPublishTasks(project))
}

val spineBaseVersion: String by extra

dependencies {
    protobuf("io.spine:spine-base:$spineBaseVersion")
    protobuf("io.spine.tools:spine-tool-base:$spineBaseVersion")
    Deps.build.protobuf.forEach { protobuf(it) }

    // TODO:2019-10-25:dmytro.dashenkov: Until https://github.com/dart-lang/protobuf/issues/295 is
    //  resolved, all types must be compiled in a single batch.

    testProtobuf("io.spine:spine-base:$spineBaseVersion")
    testProtobuf("io.spine.tools:spine-tool-base:$spineBaseVersion")
    Deps.build.protobuf.forEach { testProtobuf(it) }
}

tasks["testDart"].dependsOn("generateDart")

tasks.generateDart {
    descriptor = protoDart.testDescriptorSet
    target = "$projectDir/test"
    standardTypesPackage = "dart_code_gen"
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
