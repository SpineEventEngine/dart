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

buildscript {

    io.spine.gradle.internal.DependencyResolution.defaultRepositories(repositories)

    val spineBaseVersion: String by extra

    dependencies {
        classpath("io.spine.tools:spine-model-compiler:$spineBaseVersion")
    }
}

plugins {
    java
    id("org.gretty") version ("3.0.4")
    id("com.github.psxpaul.execfork") version ("0.1.13")
}

apply {
    plugin("io.spine.tools.spine-model-compiler")
    from("$rootDir/config/gradle/model-compiler.gradle")
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

val spineWebVersion: String by extra

dependencies {
    implementation("io.spine.gcloud:spine-firebase-web:$spineWebVersion")
    implementation(io.spine.gradle.internal.Grpc.protobuf)

    // Exclude transitive Proto messages from Firebase Admin SDK, for two reasons:
    //
    // 1) they use `optional` fields, and require `experimental_allow_proto3_optional` flag set.
    // 2) we don't want to generate Java code from the transitive Proto types,
    //    as they were already generated in their respective libraries, and arrive
    //    to us as Java `.class` files.
    //
    protobuf("io.spine.gcloud:spine-firebase-web:$spineWebVersion") {
        exclude(group = "com.google.firebase", module = "firebase-admin")
        exclude(group = "com.google.api.grpc", module = "*")
        exclude(group = "io.spine", module = "*")
    }
}

configurations.all {
    resolutionStrategy {
        force(
            "com.google.code.gson:gson:2.7",
            "com.google.protobuf:protobuf-java-util:${io.spine.gradle.internal.Versions.protobuf}"
        )
    }
}

gretty {
    contextPath = "/"
    httpPort = 8080
    debugPort = 5005
    isDebugSuspend = true
    jvmArgs = listOf("-Dio.spine.tests=true", "-Xverify:none")
    servletContainer = "jetty9.4"
    managedClassReload = false
    fastReload = false
}
