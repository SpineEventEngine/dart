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

import com.google.protobuf.gradle.testProtobuf
import io.spine.internal.gradle.dart.dart
import io.spine.internal.gradle.dart.plugin.protobuf
import io.spine.internal.gradle.dart.task.build
import io.spine.internal.gradle.dart.task.integrationTest
import io.spine.internal.gradle.dart.task.testDart

plugins {
    codegen
    dart
    id("io.spine.tools.proto-dart-plugin")
}

dependencies {
    testProtobuf(project(":test-app"))
}

dart {
    plugins {
        protobuf()
        protoDart { testDir.set(integrationTestDir) }
    }
    tasks {
        build {
            assemble { dependsOn("generateDart") }
            testDart { enabled = false }
        }

        integrationTest()

        generateDart {
            descriptor = protoDart.testDescriptorSet
            target = "$projectDir/integration-test"
        }
    }
}
