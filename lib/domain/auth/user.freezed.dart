// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'notes_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
class _$NotesUserTearOff {
  const _$NotesUserTearOff();

// ignore: unused_element
  _NotesUser call({@required UniqueId id, User firebaseUser}) {
    return _NotesUser(
      id: id,
      firebaseUser: firebaseUser,
    );
  }
}

/// @nodoc
// ignore: unused_element
const $NotesUser = _$NotesUserTearOff();

/// @nodoc
mixin _$NotesUser {
  UniqueId get id;
  User get firebaseUser;

  $NotesUserCopyWith<NotesUser> get copyWith;
}

/// @nodoc
abstract class $NotesUserCopyWith<$Res> {
  factory $NotesUserCopyWith(NotesUser value, $Res Function(NotesUser) then) = _$NotesUserCopyWithImpl<$Res>;
  $Res call({UniqueId id, User firebaseUser});
}

/// @nodoc
class _$NotesUserCopyWithImpl<$Res> implements $NotesUserCopyWith<$Res> {
  _$NotesUserCopyWithImpl(this._value, this._then);

  final NotesUser _value;
  // ignore: unused_field
  final $Res Function(NotesUser) _then;

  @override
  $Res call({
    Object id = freezed,
    Object firebaseUser = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as UniqueId,
      firebaseUser: firebaseUser == freezed ? _value.firebaseUser : firebaseUser as User,
    ));
  }
}

/// @nodoc
abstract class _$NotesUserCopyWith<$Res> implements $NotesUserCopyWith<$Res> {
  factory _$NotesUserCopyWith(_NotesUser value, $Res Function(_NotesUser) then) = __$NotesUserCopyWithImpl<$Res>;
  @override
  $Res call({UniqueId id, User firebaseUser});
}

/// @nodoc
class __$NotesUserCopyWithImpl<$Res> extends _$NotesUserCopyWithImpl<$Res> implements _$NotesUserCopyWith<$Res> {
  __$NotesUserCopyWithImpl(_NotesUser _value, $Res Function(_NotesUser) _then) : super(_value, (v) => _then(v as _NotesUser));

  @override
  _NotesUser get _value => super._value as _NotesUser;

  @override
  $Res call({
    Object id = freezed,
    Object firebaseUser = freezed,
  }) {
    return _then(_NotesUser(
      id: id == freezed ? _value.id : id as UniqueId,
      firebaseUser: firebaseUser == freezed ? _value.firebaseUser : firebaseUser as User,
    ));
  }
}

/// @nodoc
class _$_NotesUser extends _NotesUser {
  const _$_NotesUser({@required this.id, this.firebaseUser})
      : assert(id != null),
        super._();

  @override
  final UniqueId id;
  @override
  final User firebaseUser;

  @override
  String toString() {
    return 'NotesUser(id: $id, firebaseUser: $firebaseUser)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _NotesUser &&
            (identical(other.id, id) || const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.firebaseUser, firebaseUser) || const DeepCollectionEquality().equals(other.firebaseUser, firebaseUser)));
  }

  @override
  int get hashCode => runtimeType.hashCode ^ const DeepCollectionEquality().hash(id) ^ const DeepCollectionEquality().hash(firebaseUser);

  @override
  _$NotesUserCopyWith<_NotesUser> get copyWith => __$NotesUserCopyWithImpl<_NotesUser>(this, _$identity);
}

abstract class _NotesUser extends NotesUser {
  const _NotesUser._() : super._();
  const factory _NotesUser({@required UniqueId id, User firebaseUser}) = _$_NotesUser;

  @override
  UniqueId get id;
  @override
  User get firebaseUser;
  @override
  _$NotesUserCopyWith<_NotesUser> get copyWith;
}
