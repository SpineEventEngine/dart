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

import 'package:spine_client/spine/client/filters.pb.dart';
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/src/known_types.dart';
import 'package:spine_client/validate.dart';

/// Creates a target which matches messages with the given IDs and field filters.
Target target(Type type,
              {Iterable<Object>? ids = null,
               Iterable<CompositeFilter>? fieldFilters = null}) {
    var target = Target();
    target.type = _typeUrl(type);
    var filters = TargetFilters();
    if (ids != null && ids.isNotEmpty) {
        var idFilter = IdFilter();
        idFilter.id.addAll(ids.map(packId));
        filters.idFilter = idFilter;
    }
    if (fieldFilters != null && fieldFilters.isNotEmpty) {
        filters.filter.addAll(fieldFilters);
    }
    if (isDefault(filters)) {
        target.includeAll = true;
    } else {
        target.filters = filters;
    }
    return target;
}

String _typeUrl(Type type) {
    return theKnownTypes.typeUrlFrom(type);
}
