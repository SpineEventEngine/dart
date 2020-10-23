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

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/spine/client/filters.pb.dart';
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/src/known_types.dart';

/// Creates a target which matches all messages of type.
Target targetAll(GeneratedMessage instance) {
    var target = Target();
    target
        ..type = _typeUrl(instance)
        ..includeAll = true;
    return target;
}

/// Creates a target which matches messages with the given IDs.
Target targetByIds(GeneratedMessage instance, List<Object> ids) {
    var target = Target();
    target.type = _typeUrl(instance);
    var filters = TargetFilters();
    var idFilter = IdFilter();
    idFilter.id.addAll(ids.map(packId));
    filters.idFilter = idFilter;
    target.filters = filters;
    return target;
}

String _typeUrl(GeneratedMessage message) {
    return theKnownTypes.typeUrlOf(message);
}
