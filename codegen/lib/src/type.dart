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

import 'package:dart_code_gen/google/protobuf/descriptor.pb.dart';
import 'package:dart_code_gen/spine/options.pb.dart';

const _protoExtension = 'proto';
const _pbDartExtension = 'pb.dart';
const _standardTypeUrlPrefix = 'type.googleapis.com';

class MessageType {

    final FileDescriptorProto file;
    final DescriptorProto descriptor;
    final String fullName;
    final String dartClassName;

    MessageType._(this.file, this.descriptor, this.fullName, this.dartClassName);

    MessageType._fromFile(FileDescriptorProto file, DescriptorProto descriptor) :
            file = file,
            descriptor = descriptor,
            fullName = _fullName(file, descriptor),
            dartClassName = descriptor.name;

    static String _fullName(FileDescriptorProto file, DescriptorProto descriptor) =>
        "${file.package}.${descriptor.name}";

    TypeSet allChildDeclarations() {
        var children = <MessageType>{};
        for (var child in _nestedDeclarations()) {
            children.add(child);
            children.addAll(child.allChildDeclarations()
                                 .types);
        }
        return TypeSet._(children);
    }

    String get dartFilePath {
        var protoFilePath = file.name;
        var extensionIndex = protoFilePath.length - _protoExtension.length;
        var dartPath = protoFilePath.substring(0, extensionIndex) + _pbDartExtension;
        return dartPath;
    }

    String get typeUrl {
        var prefix = file.options.getExtension(Options.typeUrlPrefix) as String ?? '';
        prefix = prefix.isNotEmpty ? prefix : _standardTypeUrlPrefix;
        return "$prefix/$fullName";
    }

    Iterable<MessageType> _nestedDeclarations() =>
        descriptor.nestedType
                  .where((desc) => !desc.options.mapEntry)
                  .map((desc) => _child(desc));

    MessageType _child(DescriptorProto descriptor) {
        var name = descriptor.name;

        return MessageType._(file, descriptor, _childName(name), _childDartName(name));
    }

    String _childName(String simpleName) {
        return '${fullName}.${simpleName}';
    }

    String _childDartName(String simpleName) {
        return '${dartClassName}_${simpleName}';
    }
}

class TypeSet {

    final Set<MessageType> types;

    TypeSet._(this.types);

    factory TypeSet.of(FileDescriptorSet fileSet) {
        var typeSet = <MessageType>{};
        var files = fileSet.file;
        for (var file in files) {
            for (var type in file.messageType) {
                var messageType = MessageType._fromFile(file, type);
                typeSet.add(messageType);
                typeSet.addAll(messageType.allChildDeclarations().types);
            }
        }
        return TypeSet._(typeSet);
    }

    factory TypeSet.topLevelOnly(FileDescriptorSet fileSet) {
        var typeSet = <MessageType>{};
        var files = fileSet.file;
        for (var file in files) {
            for (var type in file.messageType) {
                var messageType = MessageType._fromFile(file, type);
                typeSet.add(messageType);
                typeSet.addAll(messageType._nestedDeclarations());
            }
        }
        return TypeSet._(typeSet);
    }
}
