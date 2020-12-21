/*
 * Copyright 2020, TeamDev. All rights reserved.
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

import io.spine.gradle.internal.DependencyResolution

buildscript {

    // As long as `buildscript` section is always evaluated first,
    // we need to apply explicitly here.
    apply(from = "$rootDir/config/gradle/dependencies.gradle")
    apply(from = "$rootDir/version.gradle.kts")

    @Suppress("RemoveRedundantQualifierName") // Cannot use imports here.
    val resolution = io.spine.gradle.internal.DependencyResolution
    val deps = io.spine.gradle.internal.Deps

    val spineBaseVersion: String by extra

    resolution.defaultRepositories(repositories)
    dependencies {
        classpath(deps.build.gradlePlugins.protobuf)
        classpath("io.spine.tools:spine-proto-dart-plugin:$spineBaseVersion")
    }

    resolution.forceConfiguration(configurations)
}

allprojects {
    apply(plugin = "java")
    apply(from = "$rootDir/version.gradle.kts")

    DependencyResolution.defaultRepositories(repositories)
}

subprojects {
    apply {
        plugin("io.spine.tools.proto-dart-plugin")
        plugin("com.google.protobuf")
        plugin("maven-publish")
    }

    version = extra["versionToPublish"]!!
}
