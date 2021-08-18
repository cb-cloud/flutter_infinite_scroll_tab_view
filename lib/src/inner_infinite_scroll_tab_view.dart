import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../infinite_scroll_tab_view.dart';
import 'cycled_list_view.dart';

const _tabAnimationDuration = Duration(milliseconds: 550);

@visibleForTesting
class InnerInfiniteScrollTabView extends StatefulWidget {
  const InnerInfiniteScrollTabView({
    Key? key,
    required this.size,
    required this.contentLength,
    required this.tabBuilder,
    required this.pageBuilder,
    this.onTabTap,
    this.separator,
    required this.textScaleFactor,
    required this.defaultTextStyle,
    required this.textDirection,
    this.backgroundColor,
    this.onPageChanged,
    required this.indicatorColor,
    this.indicatorHeight,
    required this.defaultLocale,
    required this.tabHeight,
    required this.tabPadding,
    required this.forceFixedTabWidth,
    required this.fixedTabWidthFraction,
  }) : super(key: key);

  final Size size;
  final int contentLength;
  final SelectIndexedTextBuilder tabBuilder;
  final SelectIndexedWidgetBuilder pageBuilder;
  final IndexedTapCallback? onTabTap;
  final BorderSide? separator;
  final double textScaleFactor;
  final TextStyle defaultTextStyle;
  final TextDirection textDirection;
  final Color? backgroundColor;
  final ValueChanged<int>? onPageChanged;
  final Color indicatorColor;
  final double? indicatorHeight;
  final Locale defaultLocale;
  final double tabHeight;
  final double tabPadding;
  final bool forceFixedTabWidth;
  final double fixedTabWidthFraction;

  @override
  InnerInfiniteScrollTabViewState createState() =>
      InnerInfiniteScrollTabViewState();
}

@visibleForTesting
class InnerInfiniteScrollTabViewState extends State<InnerInfiniteScrollTabView>
    with SingleTickerProviderStateMixin {
  late final _tabController = CycledScrollController(
    initialScrollOffset: centeringOffset(0),
  );
  late final _pageController = CycledScrollController();

  final ValueNotifier<bool> _isContentChangingByTab = ValueNotifier(false);
  bool _isTabForceScrolling = false;

  late double _previousTextScaleFactor = widget.textScaleFactor;

  late final ValueNotifier<double> _indicatorSize;
  final _isTabPositionAligned = ValueNotifier<bool>(true);
  final _selectedIndex = ValueNotifier<int>(0);

  final List<double> _tabTextSizes = [];
  List<double> get tabTextSizes => _tabTextSizes;

  final List<double> _tabSizesFromIndex = [];
  List<double> get tabSizesFromIndex => _tabSizesFromIndex;

  /// ページ側のスクロール位置をタブのスクロール位置にマッピングさせるためのTween群。
  ///
  /// begin: 該当するインデックスi_x要素のスクロール位置 + センタリング用オフセット
  /// end: 次のインデックスi_x+1要素のスクロール位置 + センタリング用オフセット
  /// （0 <= i < n）
  /// ただし最後の要素の場合、endは タブ要素全体の長さ + センタリング用オフセットになる。
  final List<Tween<double>> _tabOffsets = [];
  List<Tween<double>> get tabOffsets => _tabOffsets;

  final List<Tween<double>> _tabSizeTweens = [];
  List<Tween<double>> get tabSizeTweens => _tabSizeTweens;

  double get indicatorHeight =>
      widget.indicatorHeight ?? widget.separator?.width ?? 2.0;

  late final _indicatorAnimationController =
      AnimationController(vsync: this, duration: _tabAnimationDuration)
        ..addListener(() {
          if (_indicatorAnimation == null) return;
          _indicatorSize.value = _indicatorAnimation!.value;
        });
  Animation<double>? _indicatorAnimation;

  double _totalTabSizeCache = 0.0;
  double get _totalTabSize {
    if (_totalTabSizeCache != 0.0) return _totalTabSizeCache;
    _totalTabSizeCache = widget.forceFixedTabWidth
        ? _fixedTabWidth * widget.contentLength
        : _tabTextSizes.reduce((v, e) => v += e);
    return _totalTabSizeCache;
  }

  double get _fixedTabWidth => widget.size.width * widget.fixedTabWidthFraction;

  double _calculateTabSizeFromIndex(int index) {
    var size = 0.0;
    for (var i = 0; i < index; i++) {
      size += _tabTextSizes[i];
    }
    return size;
  }

  double centeringOffset(int index) {
    final tabSize =
        widget.forceFixedTabWidth ? _fixedTabWidth : _tabTextSizes[index];
    return -(widget.size.width - tabSize) / 2;
  }

  @visibleForTesting
  void calculateTabBehaviorElements(double textScaleFactor) {
    _tabTextSizes.clear();
    _tabSizesFromIndex.clear();
    _tabOffsets.clear();
    _tabSizeTweens.clear();
    _totalTabSizeCache = 0.0;

    for (var i = 0; i < widget.contentLength; i++) {
      final text = widget.tabBuilder(i, false);
      final style = (text.style ?? widget.defaultTextStyle).copyWith(
        fontFamily:
            text.style?.fontFamily ?? widget.defaultTextStyle.fontFamily,
      );
      final layoutedText = TextPainter(
        text: TextSpan(text: text.data, style: style),
        maxLines: 1,
        locale: text.locale ?? widget.defaultLocale,
        textScaleFactor: text.textScaleFactor ?? textScaleFactor,
        textDirection: widget.textDirection,
      )..layout();
      final calculatedWidth = layoutedText.size.width + widget.tabPadding * 2;
      final sizeConstraint =
          widget.forceFixedTabWidth ? _fixedTabWidth : widget.size.width;
      _tabTextSizes.add(math.min(calculatedWidth, sizeConstraint));
      _tabSizesFromIndex.add(_calculateTabSizeFromIndex(i));
    }

    for (var i = 0; i < widget.contentLength; i++) {
      if (widget.forceFixedTabWidth) {
        final offsetBegin = _fixedTabWidth * i + centeringOffset(i);
        final offsetEnd = _fixedTabWidth * (i + 1) + centeringOffset(i);
        _tabOffsets.add(Tween(begin: offsetBegin, end: offsetEnd));
      } else {
        final offsetBegin = _tabSizesFromIndex[i] + centeringOffset(i);
        final offsetEnd = i == widget.contentLength - 1
            ? _totalTabSize + centeringOffset(0)
            : _tabSizesFromIndex[i + 1] + centeringOffset(i + 1);
        _tabOffsets.add(Tween(begin: offsetBegin, end: offsetEnd));
      }

      final sizeBegin = _tabTextSizes[i];
      final sizeEnd = _tabTextSizes[(i + 1) % widget.contentLength];
      _tabSizeTweens.add(Tween(
        begin: math.min(sizeBegin, _fixedTabWidth),
        end: math.min(sizeEnd, _fixedTabWidth),
      ));
    }
  }

  @override
  void didChangeDependencies() {
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    if (_previousTextScaleFactor != textScaleFactor) {
      _previousTextScaleFactor = textScaleFactor;
      setState(() {
        calculateTabBehaviorElements(textScaleFactor);
      });
    }
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    calculateTabBehaviorElements(widget.textScaleFactor);

    _indicatorSize = ValueNotifier(_tabTextSizes[0]);

    _tabController.addListener(() {
      if (_isTabForceScrolling) return;

      if (_isTabPositionAligned.value) {
        _isTabPositionAligned.value = false;
      }
    });

    _pageController.addListener(() {
      if (_isContentChangingByTab.value) return;

      final currentIndexDouble = _pageController.offset / widget.size.width;
      final currentIndex = currentIndexDouble.floor();
      final modIndex = currentIndexDouble.round() % widget.contentLength;

      final currentIndexDecimal =
          currentIndexDouble - currentIndexDouble.floor();

      _tabController.jumpTo(_tabOffsets[currentIndex % widget.contentLength]
          .transform(currentIndexDecimal));

      _indicatorSize.value = _tabSizeTweens[currentIndex % widget.contentLength]
          .transform(currentIndexDecimal);

      if (!_isTabPositionAligned.value) {
        _isTabPositionAligned.value = true;
      }

      if (modIndex != _selectedIndex.value) {
        widget.onPageChanged?.call(modIndex);
        _selectedIndex.value = modIndex;
        HapticFeedback.selectionClick();
      }
    });
  }

  void _onTapTab(int modIndex, int rawIndex) async {
    _isContentChangingByTab.value = true;

    widget.onTabTap?.call(modIndex);
    widget.onPageChanged?.call(modIndex);

    HapticFeedback.selectionClick();
    _isTabPositionAligned.value = true;

    final sizeOnIndex = widget.forceFixedTabWidth
        ? _fixedTabWidth * modIndex
        : _tabSizesFromIndex[modIndex];
    final section = rawIndex.isNegative
        ? (rawIndex + 1) ~/ widget.contentLength - 1
        : rawIndex ~/ widget.contentLength;
    final targetOffset = _totalTabSize * section + sizeOnIndex;
    _isTabForceScrolling = true;
    _tabController
        .animateTo(
          targetOffset + centeringOffset(modIndex),
          duration: _tabAnimationDuration,
          curve: Curves.ease,
        )
        .then((_) => _isTabForceScrolling = false);

    _indicatorAnimation =
        Tween(begin: _indicatorSize.value, end: _tabTextSizes[modIndex])
            .animate(_indicatorAnimationController);
    _indicatorAnimationController.forward(from: 0);

    // 現在のスクロール位置とページインデックスを取得
    final currentOffset = _pageController.offset;

    // 選択したページまでの距離を計算する
    // modの境界をまたぐ場合を考慮して、近い方向を指すように正負を調整する
    final move = calculateMoveIndexDistance(
        _selectedIndex.value, modIndex, widget.contentLength);
    final targetPageOffset = currentOffset + move * widget.size.width;

    _selectedIndex.value = modIndex;

    await _pageController.animateTo(
      targetPageOffset,
      duration: _tabAnimationDuration,
      curve: Curves.ease,
    );

    _isContentChangingByTab.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: widget.tabHeight + (widget.separator?.width ?? 0),
              child: ValueListenableBuilder<bool>(
                valueListenable: _isContentChangingByTab,
                builder: (context, value, _) => AbsorbPointer(
                  absorbing: value,
                  child: _buildTabSection(),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isTabPositionAligned,
                builder: (context, value, _) => Visibility(
                  visible: value,
                  child: _CenteredIndicator(
                    indicatorColor: widget.indicatorColor,
                    size: _indicatorSize,
                    indicatorHeight: indicatorHeight,
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: CycledListView.builder(
            scrollDirection: Axis.horizontal,
            contentCount: widget.contentLength,
            controller: _pageController,
            physics: const PageScrollPhysics(),
            itemBuilder: (context, modIndex, rawIndex) => SizedBox(
              width: widget.size.width,
              child: ValueListenableBuilder<int>(
                valueListenable: _selectedIndex,
                builder: (context, value, _) =>
                    widget.pageBuilder(context, modIndex, value == modIndex),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    return CycledListView.builder(
      scrollDirection: Axis.horizontal,
      controller: _tabController,
      contentCount: widget.contentLength,
      itemBuilder: (context, modIndex, rawIndex) {
        final tab = Material(
          color: widget.backgroundColor,
          child: InkWell(
            onTap: () => _onTapTab(modIndex, rawIndex),
            child: ValueListenableBuilder<int>(
              valueListenable: _selectedIndex,
              builder: (context, index, _) => ValueListenableBuilder<bool>(
                valueListenable: _isTabPositionAligned,
                builder: (context, tab, _) => _TabContent(
                  isTabPositionAligned: tab,
                  selectedIndex: index,
                  indicatorColor: widget.indicatorColor,
                  tabPadding: widget.tabPadding,
                  modIndex: modIndex,
                  tabBuilder: widget.tabBuilder,
                  separator: widget.separator,
                  tabWidth: widget.forceFixedTabWidth
                      ? _fixedTabWidth
                      : _tabTextSizes[modIndex],
                  indicatorHeight: indicatorHeight,
                  indicatorWidth: _tabTextSizes[modIndex],
                ),
              ),
            ),
          ),
        );

        return widget.forceFixedTabWidth
            ? SizedBox(width: _fixedTabWidth, child: tab)
            : tab;
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _indicatorAnimationController.dispose();
    super.dispose();
  }
}

/// 選択したページまでの距離を計算する。
///
/// modの境界をまたぐ場合を考慮して、近い方向を指すように正負を調整する。
@visibleForTesting
int calculateMoveIndexDistance(int current, int selected, int length) {
  final tabDistance = selected - current;
  var move = tabDistance;
  if (tabDistance.abs() >= length ~/ 2) {
    move += (-tabDistance.sign * length);
  }

  return move;
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    Key? key,
    required this.isTabPositionAligned,
    required this.selectedIndex,
    required this.modIndex,
    required this.tabPadding,
    required this.indicatorColor,
    required this.tabBuilder,
    this.separator,
    required this.indicatorHeight,
    required this.indicatorWidth,
    required this.tabWidth,
  }) : super(key: key);

  final int modIndex;
  final int selectedIndex;
  final bool isTabPositionAligned;
  final double tabPadding;
  final Color indicatorColor;
  final SelectIndexedTextBuilder tabBuilder;
  final BorderSide? separator;
  final double indicatorHeight;
  final double indicatorWidth;
  final double tabWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: tabWidth,
          padding: EdgeInsets.symmetric(horizontal: tabPadding),
          decoration: BoxDecoration(
            border: Border(bottom: separator ?? BorderSide.none),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: tabBuilder(modIndex, selectedIndex == modIndex),
            ),
          ),
        ),
        if (selectedIndex == modIndex && !isTabPositionAligned)
          Positioned(
            bottom: 0,
            height: indicatorHeight,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: indicatorWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(indicatorHeight),
                  color: indicatorColor,
                ),
              ),
            ),
          )
      ],
    );
  }
}

class _CenteredIndicator extends StatelessWidget {
  const _CenteredIndicator({
    Key? key,
    required this.indicatorColor,
    required this.size,
    required this.indicatorHeight,
  }) : super(key: key);

  final Color indicatorColor;
  final ValueNotifier<double> size;
  final double indicatorHeight;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: size,
      builder: (context, value, _) => Center(
        child: Container(
          height: indicatorHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(indicatorHeight),
            color: indicatorColor,
          ),
          width: value,
        ),
      ),
    );
  }
}
