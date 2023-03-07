/*
 * Copyright 2021, TeamDev. All rights reserved.
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

/**
 * Declares the version of the artifacts to publish and versions of
 * project-specific general dependencies.
 *
 * This file is used in both module `build.gradle.kts` scripts and in the integration tests,
 * as we want to manage the versions in a single source.
 *
 * This file is copied to the root of the project ONLY if there's no file with such a name
 * already in the root directory.
 */

/**
 * Version of this library.
 */
val dart = "1.9.0-SNAPSHOT.12"

/**
 * Versions of the Spine libraries that `core-java` depends on.
 */
val base = "1.9.0-SNAPSHOT.6"
val web = "1.9.0-SNAPSHOT.12"

project.extra.apply {
    this["versionToPublish"] = dart
    this["spineBaseVersion"] = base
    this["spineWebVersion"] = web
}
