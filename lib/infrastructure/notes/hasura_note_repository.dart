import 'package:dartz/dartz.dart';
import 'package:graphql/client.dart';
import 'package:injectable/injectable.dart';
import 'package:kt_dart/kt.dart';
import 'package:notes_firebase_ddd_course/domain/auth/i_auth_facade.dart';
import 'package:notes_firebase_ddd_course/domain/auth/notes_user.dart';
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
  final IAuthFacade authFacade;
  GraphQLClient client;

  HasuraNoteRepository(this.authFacade) {
    final _httpLink = HttpLink('https://ddd-firebase-course.hasura.app/v1/graphql');

    final _wsLink = WebSocketLink(
      'wss://ddd-firebase-course.hasura.app/v1/graphql',
      config: SocketClientConfig(
        initialPayload: getTokenFunction,
      ),
    );

    final _authLink = AuthLink(
      getToken: () async {
        final Map<String, dynamic> map = await getTokenFunction();
        return Future.value(map['Authorization'] as String);
      },
    );

    /// subscriptions must be split otherwise `HttpLink` will. swallow them
    final Link _link = Link.split((request) => request.isSubscription, _wsLink, _httpLink);

    client = GraphQLClient(
      /// **NOTE** The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(),
      link: _authLink.concat(_link),
      // defaultPolicies: DefaultPolicies(
      //   query: Policies(
      //     fetch: FetchPolicy.networkOnly,
      //     error: ErrorPolicy.all,
      //     cacheReread: CacheRereadPolicy.mergeOptimistic,
      //   ),
      //   subscribe: Policies(
      //     fetch: FetchPolicy.networkOnly,
      //     error: ErrorPolicy.all,
      //     cacheReread: CacheRereadPolicy.mergeOptimistic,
      //   ),
      //   watchMutation: Policies(
      //     fetch: FetchPolicy.networkOnly,
      //     error: ErrorPolicy.all,
      //     cacheReread: CacheRereadPolicy.mergeOptimistic,
      //   ),
      // ),
    );
  }

  Future<Map<String, dynamic>> getTokenFunction() async {
    final option = await authFacade.getSignedInUser();
    return option.fold(
      () => null,
      (user) async {
        final idToken = await user.getIdToken();
        return {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
//          'X-Hasura-Role': 'user',
        };
      },
    );
  }

  Iterable<Note> filterUncompleted(Iterable<Note> notes) {
    return notes.where((note) => note.todos.getOrCrash().any((todoItem) => !todoItem.done));
  }

  @override
  Stream<Either<NoteFailure, KtList<Note>>> watchAll() {
    return _watch();
  }

  @override
  Stream<Either<NoteFailure, KtList<Note>>> watchUncompleted() {
    return _watch(onlyUncompleted: true);
  }

  Stream<Either<NoteFailure, KtList<Note>>> _watch({bool onlyUncompleted = false}) async* {
    const String query = r'''
      subscription NotesQuery($userId: String!) {
        notes(where: {user_id: {_eq: $userId}}) {
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
    yield* stream
        .map(
          (result) {
            if (result.hasException) {
              throw result.exception;
            }
            return result;
          },
        )
        .map((result) => fromQueryResult(result))
        .map((rawNotes) => rawNotes.map((rawNote) => NoteDto.fromHasura(rawNote).toDomain()))
        .map(onlyUncompleted ? filterUncompleted : id)
        .map((notes) => right<NoteFailure, KtList<Note>>(notes.toImmutableList()))
        .onErrorReturnWith(
          (e) {
            if (e is OperationException && e.toString().contains('PERMISSION_DENIED')) {
              return left(const NoteFailure.insufficientPermission());
            } else {
              // log.error(e.toString());
              return left(NoteFailure.unexpected(failureData: e));
            }
          },
        );
  }

  Iterable<Map<String, dynamic>> fromQueryResult(QueryResult result) {
    final List<Object> list = result.data['notes'] as List<Object>;
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
    //     return left(NoteFailure.unexpected(e));
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
    //     return left(NoteFailure.unexpected(e));
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
    //     return left(NoteFailure.unexpected(failureData: e));
    //   }
    // }
  }
}
