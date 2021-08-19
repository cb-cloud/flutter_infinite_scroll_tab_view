## 1.0.3
FEAT
- Added `forceFixedTabWidth` `fixedTabWidthFraction` properties.
  - `forceFixedTabWidth` makes the Widget force to use fixed-size tab.
  - `fixedTabWidthFraction` determines tab width fraction from Widget size when using fixed-size tab.

## 1.0.2
FIX
- Removed `LayoutBuilder` from root of `InfiniteScrollTabView`. This change prevents some performance issue.

## 1.0.1
FIX
- Added `indicatorHeight` property to `InfintieScrollTabView`. It will override indicator height if specified non-null value.
- The tabs now prevent double tap.
- Fixed a bug that tapping tab causes changing page to unexpected index sometime.
## 1.0.0
FEAT
- Changed internal structure about indicator. It considers specified `separator`'s size now.
- Added some doc comments and tests.
- Tab sizes now re-calculate on changed text size by OS setting.

## 0.1.0

First release.