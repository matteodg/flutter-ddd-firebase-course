import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:kt_dart/kt.dart';
import 'package:mockito/mockito.dart';
import 'package:notes_firebase_ddd_course/application/notes/note_watcher/note_watcher_bloc.dart';
import 'package:notes_firebase_ddd_course/domain/core/value_objects.dart';
import 'package:notes_firebase_ddd_course/domain/notes/i_note_repository.dart';
import 'package:notes_firebase_ddd_course/domain/notes/note.dart';
import 'package:notes_firebase_ddd_course/domain/notes/todo_item.dart';
import 'package:notes_firebase_ddd_course/domain/notes/value_objects.dart';

class MockNoteRepository extends Mock implements INoteRepository {}

void main() {
  MockNoteRepository noteRepository;

  setUp(() {
    noteRepository = MockNoteRepository();
  });

  group('NoteWatcherBloc', () {
    blocTest<NoteWatcherBloc, NoteWatcherState>(
      'should have initial state at creation',
      build: () {
        final bloc = NoteWatcherBloc(noteRepository);
        expect(bloc.state, equals(const NoteWatcherState.initial()));
        return bloc;
      },
    );

    blocTest<NoteWatcherBloc, NoteWatcherState>(
      'should call watchAll from repository and get an empty list',
      build: () {
        when(noteRepository.watchAll()).thenAnswer(
          (_) => Stream.value(right(KtList.empty())),
        );
        return NoteWatcherBloc(noteRepository);
      },
      act: (bloc) {
        bloc.add(const NoteWatcherEvent.watchAllStarted());
      },
      expect: [
        const NoteWatcherState.loadInProgress(),
        NoteWatcherState.loadSuccess(KtList.empty()),
      ],
      verify: (bloc) {
        verify(noteRepository.watchAll()).called(1);
      },
    );

    final aaa = Note(
      id: UniqueId.fromUniqueString('AAA'),
      body: NoteBody('my note AAA'),
      color: NoteColor(Colors.red),
      todos: List3<TodoItem>(KtList.of()),
    );
    final bbb = Note(
      id: UniqueId.fromUniqueString('BBB'),
      body: NoteBody('my note BBB'),
      color: NoteColor(Colors.red),
      todos: List3<TodoItem>(KtList.of(
        TodoItem(id: UniqueId.fromUniqueString('BBBtodo'), name: TodoName('my BBBtodo'), done: true),
      )),
    );
    final ccc = Note(
      id: UniqueId.fromUniqueString('CCC'),
      body: NoteBody('my note CCC'),
      color: NoteColor(Colors.red),
      todos: List3<TodoItem>(KtList.of(
        TodoItem(id: UniqueId.fromUniqueString('CCCtodo'), name: TodoName('my CCCtodo'), done: false),
      )),
    );
    final allNotes = KtList<Note>.of(
      // completed
      aaa, bbb,
      // uncompleted
      ccc,
    );
    final uncompletedNotes = KtList<Note>.of(
      // uncompleted
      ccc,
    );
    blocTest<NoteWatcherBloc, NoteWatcherState>(
      'should load all and then uncompleted',
      build: () {
        when(noteRepository.watchAll()).thenAnswer(
          (_) => Stream.value(right(allNotes)),
        );
        when(noteRepository.watchUncompleted()).thenAnswer(
          (_) => Stream.value(right(uncompletedNotes)),
        );
        return NoteWatcherBloc(noteRepository);
      },
      act: (bloc) {
        bloc.add(const NoteWatcherEvent.watchAllStarted());
        bloc.add(const NoteWatcherEvent.watchUncompletedStarted());
      },
      expect: [
        const NoteWatcherState.loadInProgress(),
        NoteWatcherState.loadSuccess(allNotes),
        //const NoteWatcherState.loadInProgress(),
        NoteWatcherState.loadSuccess(uncompletedNotes),
      ],
      verify: (bloc) {
        verify(noteRepository.watchAll()).called(1);
        verify(noteRepository.watchUncompleted()).called(1);
      },
    );
    test('test using flutter_test instead of bloc_test', () async {
      when(noteRepository.watchAll()).thenAnswer(
        (_) => Stream.value(right(allNotes)),
      );
      when(noteRepository.watchUncompleted()).thenAnswer(
        (_) => Stream.value(right(uncompletedNotes)),
      );
      final bloc = NoteWatcherBloc(noteRepository);
      expectLater(
        bloc,
        emitsInOrder([
          const NoteWatcherState.loadInProgress(),
          NoteWatcherState.loadSuccess(allNotes),
          // const NoteWatcherState.loadInProgress(),
          NoteWatcherState.loadSuccess(uncompletedNotes),
          NoteWatcherState.loadSuccess(allNotes),
          NoteWatcherState.loadSuccess(uncompletedNotes),
        ]),
      ).then((value) {
        verify(noteRepository.watchAll()).called(2);
        verify(noteRepository.watchUncompleted()).called(2);
      });
      bloc.add(const NoteWatcherEvent.watchAllStarted());
      bloc.add(const NoteWatcherEvent.watchUncompletedStarted());
      bloc.add(const NoteWatcherEvent.watchAllStarted());
      bloc.add(const NoteWatcherEvent.watchUncompletedStarted());
    });
  });
}
