import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:metmusic/core/models/track.dart';
import 'package:metmusic/features/player/audio/queue_manager.dart';

Track _track(String id) => Track(trackId: id, title: 'Track $id');

void main() {
  group('QueueManager', () {
    test('arranca vacío', () {
      final queue = QueueManager();
      expect(queue.isEmpty, isTrue);
      expect(queue.current, isNull);
      expect(queue.currentIndex, -1);
      expect(queue.nextIndex(), isNull);
      expect(queue.previousIndex(), isNull);
    });

    test('setQueue fija el índice inicial y respeta los límites', () {
      final queue = QueueManager()
        ..setQueue([_track('a'), _track('b'), _track('c')], startIndex: 1);

      expect(queue.tracks.length, 3);
      expect(queue.current!.trackId, 'b');
      expect(queue.nextIndex(), 2);
      expect(queue.previousIndex(), 0);

      queue.setQueue([_track('x')], startIndex: 99);
      expect(queue.currentIndex, 0);
    });

    test('sin repeat, el final de la cola no tiene siguiente', () {
      final queue = QueueManager()
        ..setQueue([_track('a'), _track('b')], startIndex: 1);
      expect(queue.hasNext, isFalse);
      expect(queue.nextIndex(), isNull);
    });

    test('repeat all cicla ambos extremos', () {
      final queue = QueueManager()
        ..setQueue([_track('a'), _track('b'), _track('c')], startIndex: 2)
        ..setRepeat(LoopMode.all);

      expect(queue.nextIndex(), 0);

      queue.setCurrentIndex(0);
      expect(queue.previousIndex(), 2);
    });

    test('repeat one avanza solo cuando es manual', () {
      final queue = QueueManager()
        ..setQueue([_track('a'), _track('b')])
        ..setRepeat(LoopMode.one);

      expect(queue.nextIndex(), 0); // automático: repite
      expect(queue.nextIndex(manual: true), 1); // manual: avanza
    });

    test('shuffle mantiene el track actual al frente del orden', () {
      final queue = QueueManager()
        ..setQueue(
          [for (var i = 0; i < 12; i++) _track('t$i')],
          startIndex: 3,
        )
        ..setShuffle(true);

      expect(queue.shuffle, isTrue);
      expect(queue.nextIndex(), isNot(3));

      // El orden completo debe seguir siendo una permutación válida.
      final visited = <int>{3};
      var index = queue.nextIndex();
      while (index != null && visited.add(index)) {
        queue.setCurrentIndex(index);
        index = queue.nextIndex();
      }
      expect(visited.length, 12);
    });

    test('removeAt ajusta currentIndex y el track actual', () {
      final queue = QueueManager()
        ..setQueue([_track('a'), _track('b'), _track('c')], startIndex: 2);

      final removedCurrent = queue.removeAt(2);
      expect(removedCurrent, isTrue);
      expect(queue.currentIndex, 1);
      expect(queue.current!.trackId, 'b');

      queue.removeAt(0);
      expect(queue.currentIndex, 0);
      expect(queue.tracks.single.trackId, 'b');
    });

    test('move reordena y sigue al track actual', () {
      final queue = QueueManager()
        ..setQueue([_track('a'), _track('b'), _track('c')], startIndex: 0);

      queue.move(0, 2);
      expect(queue.tracks.map((t) => t.trackId).toList(), ['b', 'c', 'a']);
      expect(queue.current!.trackId, 'a');
      expect(queue.currentIndex, 2);
    });

    test('clear vacía la cola', () {
      final queue = QueueManager()..setQueue([_track('a')]);
      queue.clear();
      expect(queue.isEmpty, isTrue);
      expect(queue.current, isNull);
    });
  });
}
