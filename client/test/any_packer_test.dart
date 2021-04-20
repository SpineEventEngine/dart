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

import 'package:fixnum/fixnum.dart';
import 'package:spine_client/google/protobuf/any.pb.dart';
import 'package:spine_client/google/protobuf/timestamp.pb.dart';
import 'package:spine_client/google/protobuf/wrappers.pb.dart';
import 'package:spine_client/spine/core/user_id.pb.dart';
import 'package:spine_client/spine/time/time.pb.dart';
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/time.dart';
import 'package:spine_client/unknown_type.dart';
import 'package:test/test.dart';
import 'package:spine_client/google/protobuf/type.pb.dart';

void main() {
    group('AnyPacker should', () {
        test('pack a known type', () {
            var timestamp = now();
            var any = pack(timestamp);
            expect(any.canUnpackInto(Timestamp()), isTrue);
            expect(unpack(any), timestamp);
        });

        test('not unpack an unknown type', () {
            var any = Any()
                ..typeUrl = 'types.example.com/unknown.Type'
                ..value = [42];
            expect(() { unpack(any); }, throwsA(isA<UnknownTypeError>()));
        });

        test('convert enum value to Any', () {
            var month = Month.JANUARY;
            var any = packObject(month);
            expect(unpack(any), isA<EnumValue>());
            expect((unpack(any) as EnumValue).name, equals(month.name));
            expect((unpack(any) as EnumValue).number, equals(month.value));
        });

        test('convert int IDs to Any', () {
            var rawId = 42;
            var anyId = packId(rawId);
            expect(unpack(anyId), isA<Int32Value>());
            expect((unpack(anyId) as Int32Value).value, equals(rawId));
        });

        test('convert long IDs to Any', () {
            var rawId = Int64.ONE;
            var anyId = packId(rawId);
            expect(unpack(anyId), isA<Int64Value>());
            expect((unpack(anyId) as Int64Value).value, equals(rawId));
        });

        test('convert String IDs to Any', () {
            var rawId = 'foo bar';
            var anyId = packId(rawId);
            expect(unpack(anyId), isA<StringValue>());
            expect((unpack(anyId) as StringValue).value, equals(rawId));
        });

        test('convert message IDs to Any', () {
            var rawId = UserId()..value = '42';
            var anyId = packId(rawId);
            expect(unpack(anyId), isA<UserId>());
            expect(unpack(anyId), equals(rawId));
        });

        test('convert Any IDs to Any', () {
            var rawId = pack(UserId()..value = '314');
            var anyId = packId(rawId);
            expect(unpack(anyId), isA<UserId>());
            expect(unpack(anyId), equals(unpack(rawId)));
        });

        test('throw ArgumentError on an unsupported ID type', () {
            expect(() => packId(StringBuffer()..writeln('This is not supported.')),
                   throwsA(isA<ArgumentError>()));
        });
    });
}
