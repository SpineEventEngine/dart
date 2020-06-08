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

val windows = org.apache.tools.ant.taskdefs.condition.Os.isFamily(org.apache.tools.ant.taskdefs.condition.Os.FAMILY_WINDOWS)
var pubCache: String = if (windows) {
    "${System.getenv("LOCALAPPDATA")}\\Pub\\Cache\\bin"
} else {
    "${System.getProperty("user.home")}/.pub-cache/bin"
}

logger.warn("Pub cache at $pubCache ${if(File(pubCache).exists()) "exists" else "DOES NOT exist"}.")

var pubCache1: String = if (windows) {
    "${System.getenv("APPDATA")}\\Pub\\Cache\\bin"
} else {
    "${System.getProperty("user.home")}/.pub-cache/bin"
}

logger.warn("Pub cache at $pubCache1 ${if(File(pubCache1).exists()) "exists" else "DOES NOT exist"}.")

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
