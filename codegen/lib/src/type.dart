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
import 'package:path/path.dart';

const _protoExtension = '.proto';
const _pbDartExtension = '.pb.dart';
const _standardTypeUrlPrefix = 'type.googleapis.com';

const _libraryPathSeparator = '/';

abstract class Type {

    /// The file which defines this type.
    final FileDescriptorProto file;

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

    Type._(this.file, this.fullName, this.dartClassName);

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

    /// The name of the declaring Proto file, without an extension.
    ///
    /// For example, if this type is declared in `spine/net/url.proto`, returns `url`.
    ///
    String get fileNameNoExtension {
        var protoFilePath = file.name;
        var nameStartIndex = protoFilePath.lastIndexOf('/') + 1;
        var extensionIndex = protoFilePath.length - _protoExtension.length;
        var dartPath = protoFilePath.substring(nameStartIndex, extensionIndex);
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

    String dartPathRelativeTo(Type otherType) {
        var relativeDirPath = relative(_dirPath, from: otherType._dirPath);
        return relativeDirPath + _libraryPathSeparator + _dartFileName;
        // var thisPath = dartFilePath.split(_libraryPathSeparator);
        // var thisDirPath = thisPath.sublist(0, thisPath.length - 1);
        // var otherPath =  otherType.dartFilePath;
        // var relativeRidPath = relative(thisDirPath.join(_libraryPathSeparator), from: otherPath);
        // return relativeRidPath + _libraryPathSeparator + thisPath[thisPath.length - 1];
    }

    String get _dirPath {
        var thisPath = dartFilePath;
        var thisPathElements = thisPath.split(_libraryPathSeparator);
        if (thisPathElements.length <= 1) {
            return thisPath;
        } else {
            return thisPathElements.sublist(0, thisPathElements.length - 1)
                                   .join(_libraryPathSeparator);
        }
    }

    String get _dartFileName => dartFilePath.split(_libraryPathSeparator).last;

    @override
    String toString() {
        return fullName;
    }
}

/// A Protobuf message type.
class MessageType extends Type {

    /// The descriptor of this type.
    final DescriptorProto descriptor;

    MessageType._(file, this.descriptor, fullName, dartClassName) :
            super._(file, fullName, dartClassName);

    /// Creates a `MessageType` from the given descriptor and file assuming the message declaration
    /// is top-level, i.e. the type is not nested within another type.
    MessageType._fromFile(FileDescriptorProto file, this.descriptor) :
            super._(file, _fullName(file, descriptor), descriptor.name);

    static String _fullName(FileDescriptorProto file, DescriptorProto descriptor) =>
        "${file.package}.${descriptor.name}";

    List<FieldDeclaration> get fields {
        var fields = descriptor.field.map((descriptor) => FieldDeclaration(this, descriptor));
        return List.from(fields);
    }

    /// Obtains all the nested declarations of this type, including deeper levels of nesting.
    TypeSet allChildDeclarations() {
        var messages = <MessageType>{};
        var enums = <EnumType>{};
        enums.addAll(_nestedEnumDeclarations());
        for (var child in _nestedMessageDeclarations()) {
            messages.add(child);
            var grandchildren = child.allChildDeclarations();
            messages.addAll(grandchildren.messageTypes);
            enums.addAll(grandchildren.enumTypes);
        }
        return TypeSet._(messages, enums);
    }

    /// Obtains the message declarations nested in this type.
    Iterable<MessageType> _nestedMessageDeclarations() =>
        descriptor.nestedType
                  .where((desc) => !desc.options.mapEntry)
                  .map((desc) => _childMessage(desc));

    /// Obtains the message declarations nested in this type.
    Iterable<EnumType> _nestedEnumDeclarations() =>
        descriptor.enumType
                  .map((desc) => _childEnum(desc));

    MessageType _childMessage(DescriptorProto descriptor) {
        var name = descriptor.name;
        return MessageType._(file, descriptor, _childProtoName(name), _childDartName(name));
    }

    EnumType _childEnum(EnumDescriptorProto descriptor) {
        var name = descriptor.name;
        return EnumType._(file, descriptor, _childProtoName(name), _childDartName(name));
    }

    String _childProtoName(String simpleName) {
        return '${fullName}.${simpleName}';
    }

    String _childDartName(String simpleName) {
        return '${dartClassName}_${simpleName}';
    }
}

class EnumType extends Type {

    /// The descriptor of this type.
    final EnumDescriptorProto descriptor;

    EnumType._(file, this.descriptor, fullName, dartClassName) :
            super._(file, fullName, dartClassName);

    /// Creates a `MessageType` from the given descriptor and file assuming the message declaration
    /// is top-level, i.e. the type is not nested within another type.
    EnumType._fromFile(FileDescriptorProto file, this.descriptor) :
            super._(file, _fullName(file, descriptor), descriptor.name);

    static String _fullName(FileDescriptorProto file, EnumDescriptorProto descriptor) =>
        "${file.package}.${descriptor.name}";
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

    bool get isRepeated =>
        descriptor.label == FieldDescriptorProto_Label.LABEL_REPEATED;

    bool get isMap {
        if (!isRepeated) {
            return false;
        }
        if (descriptor.type != FieldDescriptorProto_Type.TYPE_MESSAGE) {
            return false;
        }
        var mapEntryTypeName = _capitalize(dartName) + 'Entry';
        return _simpleName(descriptor.typeName) == mapEntryTypeName;
    }

    String _simpleName(String fullName) {
        var start = fullName.lastIndexOf('.') + 1;
        return fullName.substring(start);
    }
}

/// A set of Protobuf message types.
class TypeSet {

    final Set<MessageType> messageTypes;
    final Set<EnumType> enumTypes;

    TypeSet._(this.messageTypes, this.enumTypes);

    /// Obtains all the message types declared in files of the given [fileSet].
    factory TypeSet.of(FileDescriptorSet fileSet) {
        var messages = <MessageType>{};
        var enums = <EnumType>{};
        var files = fileSet.file;
        for (var file in files) {
            _collectTypes(file, messages, enums);
        }
        return TypeSet._(messages, enums);
    }

    /// Obtains all the top-level message types declared in files of the given [fileSet].
    factory TypeSet.topLevelOnly(FileDescriptorSet fileSet) {
        var messages = <MessageType>{};
        var enums = <EnumType>{};
        var files = fileSet.file;
        for (var file in files) {
            var messageTypes = file.messageType.map((type) => MessageType._fromFile(file, type));
            messages.addAll(messageTypes);
            enums.addAll(_topLevelEnumTypes(file));
        }
        return TypeSet._(messages, enums);
    }

    /// Obtains all the message types declared in the given file.
    factory TypeSet.fromFile(FileDescriptorProto fileDescriptor) {
        var messages = <MessageType>{};
        var enums = <EnumType>{};
        _collectTypes(fileDescriptor, messages, enums);
        return TypeSet._(messages, enums);
    }

    static void _collectTypes(FileDescriptorProto fileDescriptor,
                              Set<MessageType> messages,
                              Set<EnumType> enums) {
        for (var type in fileDescriptor.messageType) {
            var messageType = MessageType._fromFile(fileDescriptor, type);
            messages.add(messageType);
            var children = messageType.allChildDeclarations();
            messages.addAll(children.messageTypes);
            enums.addAll(children.enumTypes);
        }
        enums.addAll(_topLevelEnumTypes(fileDescriptor));
    }

    static Iterable<EnumType> _topLevelEnumTypes(FileDescriptorProto file) {
        var enumTypes = file.enumType.map((type) => EnumType._fromFile(file, type));
        return enumTypes;
    }

    /// Find a `Type` by the given name.
    ///
    /// Throws an exception if the type cannot be found.
    ///
    Type findByName(String typeName) {
        var criterion = _noLeadingDot(typeName);
        var allTypes = <Type>{}
                    ..addAll(messageTypes)
                    ..addAll(enumTypes);
        var type = allTypes.firstWhere(
                (element) => _noLeadingDot(element.fullName) == criterion,
                orElse: () => throw Exception('Message type `${criterion}` is unknown.')
        );
        return type;
    }

    String _noLeadingDot(String value) {
        if (value.length > 1 && value.startsWith('.')) {
            return value.substring(1);
        } else {
            return value;
        }
    }
}
