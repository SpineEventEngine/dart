/*
 * Copyright 2023, TeamDev. All rights reserved.
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

import 'package:firebase_dart/firebase_dart.dart' as fb;

/// A holder of the test Firebase App.
///
/// Note that the app will only work under web environment, thus all the tests that use the app
/// should be run in the browser.
///
class FirebaseApp {

    static final FirebaseApp _instance = FirebaseApp._internal();

    var options = fb.FirebaseOptions(
        apiKey: "AIzaSyD8Nr2zrW9QFLbNS5Kg-Ank-QIZP_jo5pU",
        authDomain: "spine-dev.firebaseapp.com",
        databaseURL: "https://spine-dev.firebaseio.com",
        projectId: "spine-dev",
        storageBucket: "spine-dev.appspot.com",
        messagingSenderId: "165066236051",
        appId: "1:165066236051:web:649b727355f917bdc0ed66",
        measurementId: "G-ZVFWCSQG5Y"
    );

    late fb.FirebaseApp app;
    late fb.FirebaseDatabase database;
    bool _initialized = false;

    factory FirebaseApp() {
        return _instance;
    }

    Future<fb.FirebaseApp> init() async {
        if (!_initialized) {
            app = await fb.Firebase.initializeApp(options: options);
            database = fb.FirebaseDatabase(app: app);
            _initialized = true;
        }
        return app;
    }

    FirebaseApp._internal();
}
