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
import 'package:spine_client/spine/time/time.pb.dart';

/// Obtains a [Timestamp] with the current time.
Timestamp now() {
    return Timestamp.fromDateTime(DateTime.now());
}

/// Obtains the current time zone offset.
ZoneOffset zoneOffset() {
    var dateTime = DateTime.now();
    var zoneOffset = dateTime.timeZoneOffset;
    var offset = ZoneOffset();
    offset.amountSeconds = zoneOffset.inSeconds;
    return offset;
}

/// Obtains an identifier string for the current time zone.
///
/// There is no way to obtain an actual time zone ID in Dart. The obtained value if platform
/// dependant and usually human readable.
///
/// See https://github.com/dart-lang/sdk/issues/21758
///
ZoneId guessZoneId() {
    var dateTime = DateTime.now();
    var zoneName = dateTime.timeZoneName;
    var zoneId = ZoneId();
    zoneId.value = zoneName;
    return zoneId;
}
