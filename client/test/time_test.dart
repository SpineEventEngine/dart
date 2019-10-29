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

import 'package:spine_client/google/protobuf/timestamp.pb.dart';
import 'package:spine_client/time.dart';
import 'package:test/test.dart';

void main() {
    group('Time utility should', () {

        test('provide current time', () {
            var timestamp = now();
            var dateTime = DateTime.now();
            var expectedTime = Timestamp.fromDateTime(dateTime).seconds.toInt();
            expect(timestamp.seconds.toInt(), inInclusiveRange(expectedTime - 1, expectedTime + 1));
        });

        test('provide current zone offset', () {
            expect(zoneOffset().amountSeconds, equals(DateTime.now().timeZoneOffset.inSeconds));
        });

        test('provide human-readable zone ID', () {
            expect(guessZoneId().value, isNotEmpty);
        });
    });
}
