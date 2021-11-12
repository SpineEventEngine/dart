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

package io.spine.internal.gradle.dart

/**
 * Information about Dart environment.
 *
 * Describes used Dart-specific tools and their input and/or output files.
 */
interface DartEnvironment {

    /**
     * Path to a directory for local publications of a `Pub` package for this project.
     */
    val publicationDirectory: String

    /**
     * Command to run `Pub` package manager.
     */
    val pubExecutable: String

    /**
     * Path to `pubspec.yaml` file.
     */
    val pubSpec: String

    /**
     * Path to `.packages` file.
     */
    val packageIndex: String

    /**
     * Path to `package_config.json` file.
     */
    val packageConfig: String
}

/**
 * Configurable [DartEnvironment].
 */
class ConfigurableDartEnvironment(initialEnv: DartEnvironment) : DartEnvironment {

    override var publicationDirectory = initialEnv.publicationDirectory
    override var pubExecutable = initialEnv.pubExecutable
    override var pubSpec = initialEnv.pubSpec
    override var packageIndex = initialEnv.packageIndex
    override var packageConfig = initialEnv.packageConfig
}
