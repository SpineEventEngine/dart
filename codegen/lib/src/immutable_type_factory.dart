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

import 'package:code_builder/code_builder.dart';
import 'package:dart_code_gen/google/protobuf/descriptor.pb.dart';
import 'package:dart_code_gen/src/type.dart';

const String _builtCollection = 'package:built_collection/built_collection.dart';
const String _int64 = 'package:fixnum/fixnum.dart';

class ImmutableTypeFactory {

    final MessageType _type;
    final TypeSet _knownTypes;
    final _className;

    ImmutableTypeFactory(this._type, this._knownTypes) : _className = _type.dartClassName + "AAA";

    Class generate() {
        var getters = _type.fields.map(_buildField);
        var builderRef = refer('${_className}Builder');
        var cls = Class((b) {
            b.name = _className;
            b.abstract = true;
            b.implements.add(_builtRef(builderRef));
            b.constructors
                ..add(_privateCtor())
                ..add(_builderCtor(builderRef));
            b.methods.addAll(getters);
        });
        return cls;
    }

    Method _buildField(FieldDeclaration field) {
        return Method((b) {
            b.name = field.escapedDartName;
            b.annotations.add(refer('nullable'));
            b.type = MethodType.getter;
            b.returns = _typeOf(field, _knownTypes);
        });
    }

    Reference _builtRef(Reference builderRef) {
        return TypeReference((ref) {
            ref.symbol = 'Built';
            ref.types
                ..add(refer(_className))
                ..add(builderRef);
        });
    }

    Constructor _privateCtor() {
        var privateCtor = Constructor((b) {
            b.name = '_';
        });
        return privateCtor;
    }

    Constructor _builderCtor(Reference builderRef) {
        var builderCtor = Constructor((b) {
            b.name = _className;
            b.factory = true;
            b.optionalParameters.add(Parameter((param) {
                param.type = _updatesFuncType(builderRef);
                param.name = '';
            }));
            b.redirect = refer('_\$$_className');
        });
        return builderCtor;
    }

    Reference _updatesFuncType(Reference builderRef) {
        return FunctionType((type) {
            type.requiredParameters.add(builderRef);
        });
    }

    Reference _typeOf(FieldDeclaration field, TypeSet knownTypes) {
        var descriptor = field.descriptor;
        var type = descriptor.type;
        Reference ref = null;
        if (field.isMap) {
            ref = refer('BuiltMap', _builtCollection);
        } else {
            switch (type) {
                case FieldDescriptorProto_Type.TYPE_BOOL:
                    ref = refer('bool');
                    break;
                case FieldDescriptorProto_Type.TYPE_BYTES:
                    ref = refer('BuiltList<int>', _builtCollection);
                    break;
                case FieldDescriptorProto_Type.TYPE_DOUBLE:
                case FieldDescriptorProto_Type.TYPE_FLOAT:
                    ref = refer('double');
                    break;
                case FieldDescriptorProto_Type.TYPE_INT32:
                case FieldDescriptorProto_Type.TYPE_UINT32:
                case FieldDescriptorProto_Type.TYPE_SINT32:
                case FieldDescriptorProto_Type.TYPE_FIXED32:
                case FieldDescriptorProto_Type.TYPE_SFIXED32:
                    ref = refer('int');
                    break;
                case FieldDescriptorProto_Type.TYPE_INT64:
                case FieldDescriptorProto_Type.TYPE_UINT64:
                case FieldDescriptorProto_Type.TYPE_SINT64:
                case FieldDescriptorProto_Type.TYPE_FIXED64:
                case FieldDescriptorProto_Type.TYPE_SFIXED64:
                    ref = refer('Int64', _int64);
                    break;
                case FieldDescriptorProto_Type.TYPE_STRING:
                    ref = refer('String');
                    break;
                case FieldDescriptorProto_Type.TYPE_MESSAGE:
                case FieldDescriptorProto_Type.TYPE_ENUM:
                    var messageClass = knownTypes.findByName(descriptor.typeName);
                    var file = messageClass.dartFilePath;
                    if (file == field.declaringType.dartFilePath) {
                        ref = refer(messageClass.dartClassName);
                    } else {
                        var path = messageClass.dartPathRelativeTo(field.declaringType);
                        ref = refer(messageClass.dartClassName, path);
                    }
                    break;
            }
            if (field.isRepeated) {
                ref = TypeReference((type) => type
                                ..symbol = 'BuiltList'
                                ..types.add(ref)
                                ..url = _builtCollection);
            }
        }
        if (ref == null) {
            throw Exception('Unknown type `${type}`.');
        }
        return ref;
    }
}
