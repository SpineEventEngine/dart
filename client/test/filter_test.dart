/*
 * Copyright 2020, TeamDev. All rights reserved.
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

import 'package:spine_client/google/protobuf/timestamp.pb.dart';
import 'package:spine_client/google/protobuf/wrappers.pb.dart';
import 'package:spine_client/spine/client/filters.pb.dart';
import 'package:spine_client/spine_client.dart';
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/time.dart';
import 'package:test/test.dart';

const String firstElement = 'foo';
const String secondElement = 'bar';
const String fieldPath = '$firstElement.$secondElement';

void main() {
    group('Client should create', () {

        test('`equals` filters', () {
            var filter = eq(fieldPath, 42);
            expect(filter.operator, equals(Filter_Operator.EQUAL));
            expect(filter.fieldPath.fieldName, containsAllInOrder([firstElement, secondElement]));
            expect(unpack(filter.value), isA<Int32Value>());
        });

        test('`greater than` filters', () {
            var filter = gt(fieldPath, 2.71);
            expect(filter.operator, equals(Filter_Operator.GREATER_THAN));
            expect(filter.fieldPath.fieldName, containsAllInOrder([firstElement, secondElement]));
            expect(unpack(filter.value), isA<DoubleValue>());
        });

        test('`less than` filters', () {
            var filter = lt(fieldPath, 3.14);
            expect(filter.operator, equals(Filter_Operator.LESS_THAN));
            expect(filter.fieldPath.fieldName, containsAllInOrder([firstElement, secondElement]));
            expect(unpack(filter.value), isA<DoubleValue>());
        });

        test('`greater or equals` filters', () {
            var filter = ge(fieldPath, now());
            expect(filter.operator, equals(Filter_Operator.GREATER_OR_EQUAL));
            expect(filter.fieldPath.fieldName, containsAllInOrder([firstElement, secondElement]));
            expect(unpack(filter.value), isA<Timestamp>());
        });

        test('`less or equals` filters', () {
            var filter = le(fieldPath, now());
            expect(filter.operator, equals(Filter_Operator.LESS_OR_EQUAL));
            expect(filter.fieldPath.fieldName, containsAllInOrder([firstElement, secondElement]));
            expect(unpack(filter.value), isA<Timestamp>());
        });

        test('`all` filters', () {
            var filter = all([ge(fieldPath, 0), le(fieldPath, 1)]);
            expect(filter.operator, equals(CompositeFilter_CompositeOperator.ALL));
            expect(filter.filter.length, equals(2));
        });

        test('`either` filters', () {
            var filter = either([ge(fieldPath, 100), le(fieldPath, -1), eq(fieldPath, 42)]);
            expect(filter.operator, equals(CompositeFilter_CompositeOperator.EITHER));
            expect(filter.filter.length, equals(3));
        });
    });
}
