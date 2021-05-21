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

import io.spine.internal.gradle.Scripts

buildscript {

    io.spine.gradle.internal.DependencyResolution.defaultRepositories(repositories)

    repositories {
        repositories.maven {
            url = uri(io.spine.gradle.internal.Repos.spineSnapshots)
        }
    }

    val spineBaseVersion: String by extra

    dependencies {
        classpath("io.spine.tools:spine-mc-java:$spineBaseVersion")
    }
}

plugins {
    java
    id("org.gretty") version ("3.0.3")
    id("com.github.psxpaul.execfork") version ("0.1.13")
}

apply {
    plugin("io.spine.mc-java")
    from(Scripts.modelCompiler(project))
}

val sourcesRootDir = "$projectDir/src"
val generatedRootDir = "$projectDir/generated"
val generatedJavaDir = "$generatedRootDir/main/java"
val generatedTestJavaDir = "$generatedRootDir/test/java"
val generatedGrpcDir = "$generatedRootDir/main/grpc"
val generatedTestGrpcDir = "$generatedRootDir/test/grpc"
val generatedSpineDir = "$generatedRootDir/main/spine"
val generatedTestSpineDir = "$generatedRootDir/test/spine"


sourceSets {
    main {
        proto.srcDirs("$sourcesRootDir/main/proto")
        java.srcDirs(generatedJavaDir, "$sourcesRootDir/main/java", generatedSpineDir)
        resources.srcDirs("$generatedRootDir/main/resources")
    }
    test {
        proto.srcDirs("$sourcesRootDir/test/proto")
        java.srcDirs(generatedTestJavaDir, "$sourcesRootDir/test/java", generatedTestSpineDir)
        resources.srcDirs("$generatedRootDir/test/resources")
    }
}

val spineCoreVersion: String by extra
val spineWebVersion: String by extra

dependencies {
    implementation("io.spine:spine-server:$spineCoreVersion")
    implementation("io.spine.gcloud:spine-firebase-web:$spineWebVersion")
}

configurations.all { resolutionStrategy {
    force("com.google.code.gson:gson:2.7")
    force("io.spine:spine-server:$spineCoreVersion")
}}

gretty {
    contextPath = "/"
    httpPort = 8080
    debugPort = 5005
    isDebugSuspend = true
    jvmArgs = listOf("-Dio.spine.tests=true", "-Xverify:none")
    servletContainer = "jetty9"
    managedClassReload = false
    fastReload = false
}
