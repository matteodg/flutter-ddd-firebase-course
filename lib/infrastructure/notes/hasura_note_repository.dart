import 'package:dartz/dartz.dart';
import 'package:graphql/client.dart';
import 'package:injectable/injectable.dart';
import 'package:kt_dart/kt.dart';
import 'package:notes_firebase_ddd_course/domain/auth/i_auth_facade.dart';
import 'package:notes_firebase_ddd_course/domain/core/errors.dart';

import '../../domain/notes/i_note_repository.dart';
import '../../domain/notes/note.dart';
import '../../domain/notes/note_failure.dart';
import '../../injection.dart';
import 'note_dtos.dart';

@Environment('hasura')
@LazySingleton(as: INoteRepository)
class HasuraNoteRepository implements INoteRepository {
  GraphQLClient client;
  HasuraNoteRepository() {
    final _httpLink = HttpLink('https://mycinnamonbuns.hasura.app/v1/graphql');
    final _wsLink = WebSocketLink(
      'wss://mycinnamonbuns.hasura.app/v1/graphql',
      config: const SocketClientConfig(
        initialPayload: {
          "headers": {"X-Hasura-Admin-Secret": 'Mr9UWw68kABV2VJ6wECq4CswAF4rgFtJ'}
        },
      ),
    );

    final _authLink = AuthLink(
      headerKey: 'X-Hasura-Admin-Secret',
      getToken: () async {
        return 'Mr9UWw68kABV2VJ6wECq4CswAF4rgFtJ';
      },
    );

    /// subscriptions must be split otherwise `HttpLink` will. swallow them
    final Link _link = Link.split((request) => request.isSubscription, _wsLink, _httpLink);

    client = GraphQLClient(
      /// **NOTE** The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(),
      link: _authLink.concat(_link),
    );
  }

  @override
  Stream<Either<NoteFailure, KtList<Note>>> watchAll() async* {
    yield* _watch(false);
  }

  @override
  Stream<Either<NoteFailure, KtList<Note>>> watchUncompleted() async* {
    yield* _watch(true);
  }

  Iterable<Map<String, dynamic>> fromQueryResult(QueryResult result) {
    final List<Object> list = result.data['notes_notes'] as List<Object>;
    return list.whereType<Map<String, dynamic>>().map((Map<String, dynamic> o) => o);
  }

  Stream<Either<NoteFailure, KtList<Note>>> _watch(bool onlyUncompleted) async* {
    const String query = r'''
      subscription NotesQuery($userId: String!) {
        notes_notes(where: {user_id: {_eq: $userId}}) {
          id
          body
          color
          serverTimeStamp
          todos {
            id
            name
            done
          }
        }
      }
    ''';
    final userOption = await getIt<IAuthFacade>().getSignedInUser();
    final user = userOption.getOrElse(() => throw NotAuthenticatedError());
    final SubscriptionOptions options = SubscriptionOptions(
      document: gql(query),
      variables: <String, dynamic>{
        'userId': user.id.getOrCrash(),
      },
    );
    await for (final QueryResult result in client.subscribe(options)) {
      yield processQueryResult(result: result, onlyUncompleted: onlyUncompleted);
    }
  }

  Either<NoteFailure, KtList<Note>> processQueryResult({QueryResult result, bool onlyUncompleted}) {
    if (result.hasException) {
      final message = result.exception.toString();
      if (message.contains('PERMISSION_DENIED')) {
        return left(const NoteFailure.insufficientPermission());
      } else {
        return left(const NoteFailure.unexpected());
      }
    } else {
      final Iterable<Map<String, dynamic>> rawNotes = fromQueryResult(result);
      final Iterable<Note> notes = rawNotes.map((rawNote) => NoteDto.fromHasura(rawNote).toDomain());

      if (onlyUncompleted) {
        return right<NoteFailure, KtList<Note>>(
          notes.where((note) => note.todos.getOrCrash().any((todoItem) => !todoItem.done)).toImmutableList(),
        );
      } else {
        return right<NoteFailure, KtList<Note>>(notes.toImmutableList());
      }
    }
  }

  @override
  Future<Either<NoteFailure, Unit>> create(Note note) async {
    return left(const NoteFailure.unexpected());
    // TODO
    // try {
    //   final userDoc = await _firestore.userDocument();
    //   final noteDto = NoteDto.fromDomain(note);

    //   await userDoc.noteCollection.doc(noteDto.id).set(noteDto.toJson());

    //   return right(unit);
    // } on FirebaseException catch (e) {
    //   if (e.message.contains('PERMISSION_DENIED')) {
    //     return left(const NoteFailure.insufficientPermission());
    //   } else {
    //     return left(const NoteFailure.unexpected());
    //   }
    // }
  }

  @override
  Future<Either<NoteFailure, Unit>> update(Note note) async {
    return left(const NoteFailure.unexpected());
    // TODO
    // try {
    //   final userDoc = await _firestore.userDocument();
    //   final noteDto = NoteDto.fromDomain(note);
    //
    //   await userDoc.noteCollection.doc(noteDto.id).update(noteDto.toJson());
    //
    //   return right(unit);
    // } on FirebaseException catch (e) {
    //   if (e.message.contains('PERMISSION_DENIED')) {
    //     return left(const NoteFailure.insufficientPermission());
    //   } else if (e.message.contains('NOT_FOUND')) {
    //     return left(const NoteFailure.unableToUpdate());
    //   } else {
    //     return left(const NoteFailure.unexpected());
    //   }
    // }
  }

  @override
  Future<Either<NoteFailure, Unit>> delete(Note note) async {
    return left(const NoteFailure.unexpected());
    // TODO
    // try {
    //   final userDoc = await _firestore.userDocument();
    //   final noteId = note.id.getOrCrash();
    //
    //   await userDoc.noteCollection.doc(noteId).delete();
    //
    //   return right(unit);
    // } on FirebaseException catch (e) {
    //   if (e.message.contains('PERMISSION_DENIED')) {
    //     return left(const NoteFailure.insufficientPermission());
    //   } else if (e.message.contains('NOT_FOUND')) {
    //     return left(const NoteFailure.unableToUpdate());
    //   } else {
    //     return left(const NoteFailure.unexpected());
    //   }
    // }
  }
}
