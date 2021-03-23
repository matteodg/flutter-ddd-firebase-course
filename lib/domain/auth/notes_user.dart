import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:notes_firebase_ddd_course/domain/core/value_objects.dart';
import 'package:firebase_auth/firebase_auth.dart';
part 'user.freezed.dart';

@freezed
abstract class NotesUser implements _$NotesUser {
  const NotesUser._();

  const factory NotesUser({
    @required UniqueId id,
    User firebaseUser,
  }) = _NotesUser;

  factory NotesUser.fromFirebaseUser({
    @required User firebaseUser,
  }) {
    return NotesUser(
      id: UniqueId.fromUniqueString(firebaseUser.uid),
      firebaseUser: firebaseUser,
    );
  }

  Future<String> getIdToken() async {
    if (firebaseUser == null) {
      return Future.value();
    } else {
      final idToken = await firebaseUser.getIdToken();
      return idToken;
    }
  }
}
