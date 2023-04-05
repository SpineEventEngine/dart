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

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/spine/validate/validation_error.pb.dart';
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/known_types.dart';
import 'package:test/test.dart';

import 'google/protobuf/empty.pb.dart';
import 'google/protobuf/wrappers.pb.dart';
import 'spine/net/email_address.pb.dart';
import 'spine/people/person_name.pb.dart';
import 'spine/test/tools/dart/validation.pb.dart';
import 'types.dart' as types;

void main() {
    group('Generated validators should', () {
        setUpAll(() {
            theKnownTypes.register(types.types());
        });

        test('ignore types which should not be validated', () {
            assertValid(Empty());
        });

        test('pass valid messages', () {
            var msg = PhoneNumber()
                ..digits = '+3801111111';
            assertValid(msg);
        });

        test('pass mesages with enough required fields as by `(required_field)`', () {
            var givenNameOnly = PersonName()
                ..givenName = 'Henry';
            assertValid(givenNameOnly);
        });

        group('add to violation', () {
            test('actual value of a number', () {
                var tooManyMinutes = 1000;
                var invalidTime = LocalTime()
                    ..hours = 11
                    ..minutes = tooManyMinutes;
                assertInvalid(invalidTime);
                var violations = validate(invalidTime);
                expect(violations.length, equals(1));
                var violation = violations[0];
                var anyValue = violation.fieldValue;
                var floatValue = unpack(anyValue) as UInt32Value;
                expect(floatValue.value, equals(tooManyMinutes));
            });

            test('custom error message for (pattern)', () {
                var invalidId = TaskId()
                    ..value = 'not_enough';
                assertInvalid(invalidId);
                var violations = validate(invalidId);
                expect(violations.length, equals(1));
                var violation = violations[0];
                expect(violation.msgFormat, contains('alphanumeric'));
            });

            test('custom error message for (valid)', () {
                var invalidSnapshot = WorkInProgressSnapshot();
                invalidSnapshot.when = LocalTime()
                    ..hours = 73
                    ..minutes = 1000;
                assertInvalid(invalidSnapshot);
                var violations = validate(invalidSnapshot);
                expect(violations.length, equals(1));
                var violation = violations[0];
                expect(violation.msgFormat, contains('WIP'));
            });

            test('custom error message for (required)', () {
                var invalidId = TaskId();
                assertInvalid(invalidId);
                var violations = validate(invalidId);
                var violation = violations[0];
                expect(violation.msgFormat, endsWith('a value!'));
            });
        });

        group('report violations on', () {
            test('mismatched string', () {
                var msg = PhoneNumber()
                    ..digits = 'ABC';
                var violations = validate(msg);
                expect(violations, hasLength(equals(1)));
                var violation = violations[0];
                expect(violation.fieldPath.fieldName[0], 'digits');
                expect(violation.msgFormat, contains('`%s`'));
                expect(violation.typeName, msg.info_.qualifiedMessageName);
            });

            test('missing string', () {
                checkMissing(BinaryFile()..content = [42], 'path');
            });

            test('missing message', () {
                var message = Contact()
                    ..category = Contact_Category.PERSONAL
                    ..email.add(EmailAddress()..value = 'mollie@acme.corp');
                checkMissing(message, 'name');
            });

            test('missing enum', () {
                var name = PersonName()..givenName = 'Albert';
                var contact = Contact()
                    ..name = name
                    ..email.add(EmailAddress()..value = 'james@acme.corp');
                checkMissing(contact, 'category');
            });

            test('missing bytes', () {
                checkMissing(BinaryFile()..path = 'foo.bin', 'content');
            });
            
            test('missing repeated messages', () {
                var name = PersonName()..givenName = 'Bernard';
                var contact = Contact()
                    ..name = name
                    ..category = Contact_Category.PERSONAL;
                checkMissing(contact, 'email');
            });

            test('empty required repeated messages', () {
                var name = PersonName()..givenName = 'William';
                var contact = Contact()
                    ..name = name
                    ..category = Contact_Category.WORK
                    ..email.addAll([EmailAddress()..value = 'will@example.com', EmailAddress()]);
                checkMissing(contact, 'email');
            });

            test('missing required repeated numbers', () {
                var ticket = LotteryTicket()
                    ..magicNumber = 42;
                checkMissing(ticket, 'numbers');
            });

            test('missing required map values', () {
                var message = ContactBook();
                checkMissing(message, 'contact_by_category');
            });

            test('out of range repeated numbers', () {
                var ticket = LotteryTicket()
                    ..magicNumber = 42
                    ..numbers.addAll([1, 3, 5, 9000000]);
                var violations = validate(ticket);
                expect(violations.length, 1);
                var violation = violations[0];
                expect(violation.fieldPath.fieldName[0], 'numbers');
            });

            test('out of range int32', () {
                var time = LocalTime()
                    ..seconds = -1;
                var violations = validate(time);
                expect(violations.length, 1);
                var violation = violations[0];
                expect(violation.fieldPath.fieldName[0], 'seconds');
                expect(violation.typeName, time.info_.qualifiedMessageName);
                expect(violation.fieldValue.unpackInto(Int32Value()).value, time.seconds);
            });

            test('out of range uint32', () {
                var time = LocalTime()
                    ..hours = 42;
                var violations = validate(time);
                expect(violations.length, 1);
                var violation = violations[0];
                expect(violation.fieldPath.fieldName[0], 'hours');
                expect(violation.typeName, time.info_.qualifiedMessageName);
                expect(violation.fieldValue.unpackInto(UInt32Value()).value, time.hours);
            });

            test('out of range sfixed32', () {
                var duration = Duration()
                    ..nanos = -1024;
                var violations = validate(duration);
                expect(violations.length, 1);
                var violation = violations[0];
                expect(violation.fieldPath.fieldName[0], 'nanos');
                expect(violation.typeName, duration.info_.qualifiedMessageName);
                expect(violation.fieldValue.unpackInto(Int32Value()).value, duration.nanos);
            });

            test('several fields constraints at once', () {
                var violations = validate(Contact());
                expect(violations.length, 3);
                var emptyName = violations[0];
                expect(emptyName.fieldPath.fieldName[0], 'name');
                var emptyCategory = violations[1];
                expect(emptyCategory.fieldPath.fieldName[0], 'category');
                var emptyEmail = violations[2];
                expect(emptyEmail.fieldPath.fieldName[0], 'email');
            });

            test('several constraints on the same field', () {
                var violations = validate(PhoneNumber());
                expect(violations.length, 2);
                expect(violations[0].msgFormat, equals('A value must be set.'));
                expect(violations[1].msgFormat, contains('regular expression'));
                expect(violations[1].param.length, equals(1));
                expect(violations[1].param[0], equals('\\+?\\d{4,15}'));
            });

            test('unexpected duplicates', () {
                var contacts = Contacts()
                    ..contact.add(Contact()..category = Contact_Category.WORK)
                    ..contact.add(Contact()..category = Contact_Category.WORK);
                var violations = validate(contacts);
                expect(violations.length, 1);
                expect(violations[0].fieldPath.fieldName[0], 'contact');
                expect(violations[0].typeName, contacts.info_.qualifiedMessageName);
            });

            test('unexpected duplicates in a map', () {
                var contacts = Contacts()
                    ..contact.add(Contact()..category = Contact_Category.WORK);
                var book = ContactBook()
                    ..contactByCategory[Contact_Category.WORK.value] = contacts
                    ..contactByCategory[Contact_Category.PERSONAL.value] = contacts;
                var violations = validate(book);
                expect(violations.length, 1);
                expect(violations[0].fieldPath.fieldName[0], 'contact_by_category');
                expect(violations[0].typeName, book.info_.qualifiedMessageName);
            });

            test('required fields as defined by `(required_field)` option are not set', () {
                var surnameOnly = PersonName()
                    ..familyName = 'Jones';
                assertInvalid(surnameOnly);
                var prefixOnly = PersonName()
                    ..honorificPrefix = 'Dr.';
                assertInvalid(prefixOnly);
            });

            test('singular message fields', () {
                var validSnapshot = WorkInProgressSnapshot();
                validSnapshot.when = LocalTime()
                    ..hours = 13
                    ..minutes = 0;
                assertValid(validSnapshot);

                var invalidSnapshot = WorkInProgressSnapshot();
                invalidSnapshot.when = LocalTime()
                    ..hours = 73
                    ..minutes = 1000;
                assertInvalid(invalidSnapshot);
            });

            test('repeated message fields', () {
                var validSnapshot = WorkInProgressSnapshot();
                validSnapshot.backlog.add(TaskId()..value = 'a' * 20);
                assertValid(validSnapshot);

                var invalidSnapshot = WorkInProgressSnapshot();
                invalidSnapshot.backlog.add(TaskId()..value = 'wrong characters');
                assertInvalid(invalidSnapshot);
            });

            test('map message fields', () {
                var validSnapshot = WorkInProgressSnapshot();
                validSnapshot.assignment['John'] = TaskId()..value = 'b' * 20;
                assertValid(validSnapshot);

                var invalidSnapshot = WorkInProgressSnapshot();
                invalidSnapshot.assignment['Hank'] = TaskId()..value = 'wrong characters';
                assertInvalid(invalidSnapshot);
            });
        });
    });
}

void checkMissing(GeneratedMessage message, String fieldName) {
    var violations = validate(message);
    expect(violations, hasLength(equals(1)));
    var violation = violations[0];
    expect(violation.fieldPath.fieldName[0], fieldName);
    expect(violation.msgFormat, equals('A value must be set.'));
    expect(violation.typeName, message.info_.qualifiedMessageName);
}

void assertValid(GeneratedMessage message) {
    var violations = validate(message);
    expect(violations, isEmpty);
}

void assertInvalid(GeneratedMessage message) {
    var violations = validate(message);
    expect(violations, isNotEmpty);
    expect(violations[0].typeName, message.info_.qualifiedMessageName);
}

List<ConstraintViolation> validate(GeneratedMessage message) {
    var knownTypes = types.types();
    var typeUrl = knownTypes.defaultToTypeUrl[message.createEmptyInstance()];
    var doValidate = knownTypes.validators[typeUrl];
    var error = doValidate(message);
    return error.constraintViolation;
}
