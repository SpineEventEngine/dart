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

import 'package:dart_code_gen/google/protobuf/descriptor.pb.dart';
import 'package:dart_code_gen/spine/options.pb.dart';

const _protoExtension = 'proto';
const _pbDartExtension = 'pb.dart';
const _standardTypeUrlPrefix = 'type.googleapis.com';

/// A Protobuf message type.
class MessageType {

    /// The file which defines this type.
    final FileDescriptorProto file;

    /// The descriptor of this type.
    final DescriptorProto descriptor;

    /// The full Protobuf name of this type.
    ///
    /// For example, `spine.net.Uri.Protocol`.
    ///
    final String fullName;

    /// The name of the Dart class generated for this type.
    ///
    /// For example, `Uri_Protocol`.
    ///
    final String dartClassName;

    MessageType._(this.file, this.descriptor, this.fullName, this.dartClassName);

    /// Creates a `MessageType` from the given descriptor and file assuming the message declaration
    /// is top-level, i.e. the type is not nested within another type.
    MessageType._fromFile(FileDescriptorProto file, DescriptorProto descriptor) :
            file = file,
            descriptor = descriptor,
            fullName = _fullName(file, descriptor),
            dartClassName = descriptor.name;

    static String _fullName(FileDescriptorProto file, DescriptorProto descriptor) =>
        "${file.package}.${descriptor.name}";

    /// Relative path to the file which contains the Dart class for this message type.
    ///
    /// For example, `spine/net/url.pb.dart`.
    ///
    String get dartFilePath {
        var protoFilePath = file.name;
        var extensionIndex = protoFilePath.length - _protoExtension.length;
        var dartPath = protoFilePath.substring(0, extensionIndex) + _pbDartExtension;
        return dartPath;
    }

    /// Type URL of the message.
    ///
    /// For example, `type.spine.io/spine.net.Uri.Protocol`
    ///
    String get typeUrl {
        var prefix = file.options.getExtension(Options.typeUrlPrefix) as String ?? '';
        prefix = prefix.isNotEmpty ? prefix : _standardTypeUrlPrefix;
        return "$prefix/$fullName";
    }

    List<FieldDeclaration> get fields {
        var fields = descriptor.field.map((descriptor) => FieldDeclaration(this, descriptor));
        return List.from(fields);
    }

    /// Obtains all the nested declarations of this type, including deeper levels of nesting.
    TypeSet allChildDeclarations() {
        var children = <MessageType>{};
        for (var child in _nestedDeclarations()) {
            children.add(child);
            children.addAll(child.allChildDeclarations()
                                 .types);
        }
        return TypeSet._(children);
    }

    /// Obtains the message declarations nested in this type.
    Iterable<MessageType> _nestedDeclarations() =>
        descriptor.nestedType
                  .where((desc) => !desc.options.mapEntry)
                  .map((desc) => _child(desc));

    MessageType _child(DescriptorProto descriptor) {
        var name = descriptor.name;
        return MessageType._(file, descriptor, _childProtoName(name), _childDartName(name));
    }

    String _childProtoName(String simpleName) {
        return '${fullName}.${simpleName}';
    }

    String _childDartName(String simpleName) {
        return '${dartClassName}_${simpleName}';
    }
}

class FieldDeclaration {

    // A list of all Dart keywords.
    //
    // See https://dart.dev/guides/language/language-tour#keywords.
    //
    static const List<String> _DART_KEYWORDS = [
        'abstract',
        'else',
        'import',
        'super',
        'as',
        'enum',
        'in',
        'switch',
        'assert',
        'export',
        'interface',
        'sync',
        'async',
        'extends',
        'is',
        'this',
        'await',
        'extension',
        'library',
        'throw',
        'break',
        'external',
        'mixin',
        'true',
        'case',
        'factory',
        'new',
        'try',
        'catch',
        'false',
        'null',
        'typedef',
        'class',
        'final',
        'on',
        'var',
        'const',
        'finally',
        'operator',
        'void',
        'continue',
        'for',
        'part',
        'while',
        'covariant',
        'Function',
        'rethrow',
        'with',
        'default',
        'get',
        'return',
        'yield',
        'deferred',
        'hide',
        'set',
        'do',
        'if',
        'show',
        'dynamic',
        'implements',
        'static'
    ];

    static const List<String> _BUILT_VALUE_RESERVED = [
        'update'
    ];

    final MessageType declaringType;
    final FieldDescriptorProto descriptor;
    final String protoName;
    final String dartName;

    FieldDeclaration(this.declaringType, this.descriptor) :
            protoName = descriptor.name,
            dartName = _dartName(descriptor);

    static String _dartName(FieldDescriptorProto descriptor) {
        var protoName = descriptor.name;
        var words = protoName.split('_');
        var first = words[0];
        var capitalized = List.of(words.map(_capitalize));
        capitalized[0] = first;
        return capitalized.join('');
    }

    static String _capitalize(String word) {
        return word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}';
    }

    String get escapedDartName {
        if (_DART_KEYWORDS.contains(dartName) || _BUILT_VALUE_RESERVED.contains(dartName)) {
            return '${dartName}_${descriptor.number}';
        } else {
            return dartName;
        }
    }
}

/// A set of Protobuf message types.
class TypeSet {

    final Set<MessageType> types;

    TypeSet._(this.types);

    /// Obtains all the message types declared in files of the given [fileSet].
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

    /// Obtains all the top-level message types declared in files of the given [fileSet].
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
