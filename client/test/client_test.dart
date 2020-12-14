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

import 'package:spine_client/spine_client.dart';
import 'package:test/test.dart';

import 'fake_firebase_client.dart';
import 'spine/test/tools/dart/commands.pb.dart';
import 'spine/test/tools/dart/project.pb.dart';
import 'types.dart' as testTypes;

void main() {
    group('Client should', () {
        group('report network errors', () {

            const String NON_EXISTING_BACKEND = 'http://doesntexist.spine.io/';

            Clients clients;

            setUp(() {
                clients = Clients(NON_EXISTING_BACKEND,
                                  firebase: FakeFirebase(),
                                  typeRegistries: [testTypes.types()]);
            });

            test('when posting commands', () async {
                var future = clients.asGuest()
                                    .command(CreateProject())
                                    .postAndForget();
                expect(() async => await future, throwsA(isNotNull));
            });

            test('when sending queries', () async {
                var stream = clients.asGuest()
                                    .select(Project())
                                    .post();
                expect(() async => await stream.first, throwsA(isNotNull));
            });

            test('when subscribing to updates', () async {
                var result = clients.asGuest()
                                    .subscribeTo(Project())
                                    .post();
                var stream = result.itemAdded;
                var err = null;
                stream.handleError((error) {
                    err = error;
                });
                await stream;
                expect(err, isNotNull);
            });
        });
    });
}
