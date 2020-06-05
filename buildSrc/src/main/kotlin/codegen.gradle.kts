/*
 * Copyright 2020, TeamDev. All rights reserved.
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

import org.apache.tools.ant.taskdefs.condition.Os
import org.gradle.api.tasks.Internal
import java.io.File

val windows = Os.isFamily(Os.FAMILY_WINDOWS)
var pubCache: String
var scriptExtension: String
if (windows) {
    pubCache = "${System.getenv("APPDATA")}/Pub/Cache/bin"
    scriptExtension = ".bat"
} else {
    pubCache = "${System.getProperty("user.home")}/.pub-cache/bin"
    scriptExtension = ""
}

val command = "$pubCache/dart_code_gen$scriptExtension"

fun composeCommandLine(descriptor: File, targetDir: String, standardTypesPackage: String) =
        listOf(
                command,
                "--descriptor", "${file(descriptor)}",
                "--destination", "$targetDir/types.dart",
                "--standard-types", standardTypesPackage,
                "--import-prefix", "."
        )


open class GenerateDart : Exec() {

    @Internal
    var descriptor: Provider<out Any> = project.objects.property(File::class.java)
    @Internal
    var target: String = ""
    @Internal
    var standardTypesPackage: String = ""
}

val generateDart by tasks.creating(GenerateDart::class) {
    descriptor = project.extensions["protoDart"].withGroovyBuilder { getProperty("mainDescriptorSet") } as Property<File>
    target = "$projectDir/lib"
    standardTypesPackage = "spine_client"
}

afterEvaluate {
    tasks.withType(GenerateDart::class) {
        inputs.file(descriptor)
        commandLine(composeCommandLine(file(descriptor.get()), target, standardTypesPackage))
        dependsOn(":codegen:activateLocally")
    }
}
