import 'package:dartz/dartz.dart';
import 'package:graphql/client.dart';
import 'package:injectable/injectable.dart';
import 'package:kt_dart/kt.dart';
import 'package:notes_firebase_ddd_course/domain/auth/i_auth_facade.dart';
import 'package:notes_firebase_ddd_course/domain/core/errors.dart';
import 'package:rxdart/rxdart.dart';

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
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.mergeOptimistic,
        ),
        subscribe: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.mergeOptimistic,
        ),
        watchMutation: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.mergeOptimistic,
        ),
      ),
    );
  }

  @override
  Stream<Either<NoteFailure, KtList<Note>>> watchAll() async* {
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
    final Stream<QueryResult> stream = client.subscribe(options);
    yield* stream.map(
      (snapshot) {
        if (snapshot.hasException) {
          throw snapshot.exception;
        }
        final rawNotes = fromQueryResult(snapshot);
        return right<NoteFailure, KtList<Note>>(rawNotes.map(
          (rawNote) {
            return NoteDto.fromHasura(rawNote).toDomain();
          },
        ).toImmutableList());
      },
    ).onErrorReturnWith((e) {
      if (e is OperationException && e.toString().contains('PERMISSION_DENIED')) {
        return left(const NoteFailure.insufficientPermission());
      } else {
        // log.error(e.toString());
        return left(const NoteFailure.unexpected());
      }
    });
  }

  @override
  Stream<Either<NoteFailure, KtList<Note>>> watchUncompleted() async* {
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
    final Stream<QueryResult> stream = client.subscribe(options);
    yield* stream.map(
      (snapshot) {
        if (snapshot.hasException) {
          throw snapshot.exception;
        }
        final rawNotes = fromQueryResult(snapshot);
        Iterable<Note> notes = rawNotes.map((rawNote) => NoteDto.fromHasura(rawNote).toDomain());

        // filter out uncompleted
        notes = notes.where((note) => note.todos.getOrCrash().any((todoItem) => !todoItem.done));

        return right<NoteFailure, KtList<Note>>(notes.toImmutableList());
      },
    ).onErrorReturnWith((e) {
      if (e is OperationException && e.toString().contains('PERMISSION_DENIED')) {
        return left(const NoteFailure.insufficientPermission());
      } else {
        // log.error(e.toString());
        return left(const NoteFailure.unexpected());
      }
    });
  }

  Iterable<Map<String, dynamic>> fromQueryResult(QueryResult result) {
    final List<Object> list = result.data['notes_notes'] as List<Object>;
    return list.whereType<Map<String, dynamic>>().map((Map<String, dynamic> o) => o);
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
