import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_tab_view/infinite_scroll_tab_view.dart';

void main() {
  test(
    '''`calculateMoveIndexDistance` function should be return
      specified number distance correctly.''',
    () {
      expect(calculateMoveIndexDistance(0, 2, 10), 2);
      expect(calculateMoveIndexDistance(6, 9, 10), 3);

      expect(calculateMoveIndexDistance(9, 7, 10), -2);
      expect(calculateMoveIndexDistance(4, 1, 10), -3);

      expect(calculateMoveIndexDistance(8, 2, 10), 4);
      expect(calculateMoveIndexDistance(1, 7, 10), -4);
    },
  );
}
