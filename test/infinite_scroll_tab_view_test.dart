import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_tab_view/infinite_scroll_tab_view.dart';
import 'package:infinite_scroll_tab_view/src/inner_infinite_scroll_tab_view.dart';

void main() {
  group(
    '''`calculateMoveIndexDistance` function should be return specified number distance correctly.''',
    () {
      test(
        'In plus direction.',
        () {
          expect(calculateMoveIndexDistance(0, 2, 10), 2);
          expect(calculateMoveIndexDistance(6, 9, 10), 3);
        },
      );

      test(
        'In minus direction.',
        () {
          expect(calculateMoveIndexDistance(9, 7, 10), -2);
          expect(calculateMoveIndexDistance(4, 1, 10), -3);
        },
      );

      test(
        'While overflow/underflow situation.',
        () {
          expect(calculateMoveIndexDistance(8, 2, 10), 4);
          expect(calculateMoveIndexDistance(1, 7, 10), -4);
        },
      );
    },
  );

  group(
    'InfiniteScrollTabView should be calculate tab sizes element expectedly.',
    () {
      testWidgets('On initialize.', (tester) async {
        final strings = ['A', 'BB', 'CCC', 'DDDD'];
        await tester.pumpWidget(
          MaterialApp(
            home: InfiniteScrollTabView(
              contentLength: strings.length,
              tabPadding: 4.0,
              tabBuilder: (index, _) => Text(
                strings[index],
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.normal),
              ),
              pageBuilder: (_, index, __) => Container(),
            ),
          ),
        );

        expect(find.text('A'), findsWidgets);

        final InnerInfiniteScrollTabViewState state =
            tester.state(find.byType(InnerInfiniteScrollTabView));

        final expectedSizes = [24, 40, 56, 72];
        final expectedTotal = expectedSizes.reduce((v, e) => v += e);

        // [16 + 8, 16 * 2 + 8, 16 * 3 + 8, 16 * 4 + 8]
        // {text size} * {text length} + {tab padding} * 2
        expect(state.tabTextSizes, expectedSizes);

        expect(state.tabSizesFromIndex, [0, 24, 64, 120]);

        final offsets = [
          Tween(
            begin: 0 + state.centeringOffset(0),
            end: 24 + state.centeringOffset(1),
          ),
          Tween(
            begin: 24 + state.centeringOffset(1),
            end: 64 + state.centeringOffset(2),
          ),
          Tween(
            begin: 64 + state.centeringOffset(2),
            end: 120 + state.centeringOffset(3),
          ),
          Tween(
            begin: 120 + state.centeringOffset(3),
            end: expectedTotal + state.centeringOffset(0),
          ),
        ];
        expect(state.tabOffsets[0].begin, offsets[0].begin);
        expect(state.tabOffsets[0].end, offsets[0].end);
        expect(state.tabOffsets[1].begin, offsets[1].begin);
        expect(state.tabOffsets[1].end, offsets[1].end);
        expect(state.tabOffsets.last.begin, offsets.last.begin);
        expect(state.tabOffsets.last.end, offsets.last.end);

        final tweens = [
          Tween(begin: 24, end: 40),
          Tween(begin: 40, end: 56),
          Tween(begin: 56, end: 72),
          Tween(begin: 72, end: 24),
        ];
        expect(state.tabSizeTweens[0].begin, tweens[0].begin);
        expect(state.tabSizeTweens[0].end, tweens[0].end);
        expect(state.tabSizeTweens[1].begin, tweens[1].begin);
        expect(state.tabSizeTweens[1].end, tweens[1].end);
        expect(state.tabSizeTweens.last.begin, tweens.last.begin);
        expect(state.tabSizeTweens.last.end, tweens.last.end);
      });

      testWidgets('On textScaleFactor changed.', (tester) async {
        final strings = ['A', 'BB', 'CCC', 'DDDD'];
        await tester.pumpWidget(
          MaterialApp(
            home: InfiniteScrollTabView(
              contentLength: strings.length,
              tabPadding: 4.0,
              tabBuilder: (index, _) => Text(
                strings[index],
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.normal),
              ),
              pageBuilder: (_, index, __) => Container(),
            ),
          ),
        );

        final InnerInfiniteScrollTabViewState state =
            tester.state(find.byType(InnerInfiniteScrollTabView));

        state.calculateTabBehaviorElements(1.5);

        final expectedSizes = [32.0, 56.0, 80.0, 104.0];

        expect(state.tabTextSizes, expectedSizes);
      });
    },
  );
}
