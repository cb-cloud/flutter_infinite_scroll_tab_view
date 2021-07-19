import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cycled_list_view.dart';

typedef SelectIndexedWidgetBuilder = Widget Function(
    BuildContext context, int index, bool isSelected);

typedef SelectIndexedTextBuilder = Text Function(int index, bool isSelected);

typedef IndexedTapCallback = void Function(int index);

const _tabAnimationDuration = Duration(milliseconds: 550);

class InfiniteScrollTabView extends StatelessWidget {
  const InfiniteScrollTabView({
    Key? key,
    required this.contentLength,
    required this.tabBuilder,
    required this.pageBuilder,
    this.onTabTap,
    this.separator,
    this.backgroundColor,
    this.onPageChanged,
    this.indicatorColor = Colors.pinkAccent,
    this.tabHeight = 44.0,
    this.tabPadding = 12.0,
  }) : super(key: key);

  final int contentLength;
  final SelectIndexedTextBuilder tabBuilder;
  final SelectIndexedWidgetBuilder pageBuilder;
  final IndexedTapCallback? onTabTap;
  final BorderSide? separator;
  final Color? backgroundColor;
  final ValueChanged<int>? onPageChanged;
  final Color indicatorColor;
  final double tabHeight;
  final double tabPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) => _Content(
        size: constraint.biggest,
        contentLength: contentLength,
        tabBuilder: tabBuilder,
        pageBuilder: pageBuilder,
        onTabTap: onTabTap,
        separator: separator,
        textScaleFactor: MediaQuery.of(context).textScaleFactor,
        defaultTextStyle: DefaultTextStyle.of(context).style,
        textDirection: Directionality.of(context),
        backgroundColor: backgroundColor,
        onPageChanged: onPageChanged,
        indicatorColor: indicatorColor,
        defaultLocale: Localizations.localeOf(context),
        tabHeight: tabHeight,
        tabPadding: tabPadding,
      ),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content({
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
    required this.defaultLocale,
    required this.tabHeight,
    required this.tabPadding,
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
  final Locale defaultLocale;
  final double tabHeight;
  final double tabPadding;

  @override
  __ContentState createState() => __ContentState();
}

class __ContentState extends State<_Content>
    with SingleTickerProviderStateMixin {
  late final _tabController = CycledScrollController(
    initialScrollOffset: _centeringOffset(0),
  );
  late final _pageController = CycledScrollController();

  bool _isContentChangingByTab = false;
  bool _isTabForceScrolling = false;

  late final ValueNotifier<double> _indicatorSize;
  final _isTabPositionAligned = ValueNotifier<bool>(true);
  final _selectedIndex = ValueNotifier<int>(0);

  final List<double> _tabTextSizes = [];
  final List<double> _tabSizesFromIndex = [];

  /// ページ側のスクロール位置をタブのスクロール位置にマッピングさせるためのTween群。
  ///
  /// begin: 該当するインデックスi_x要素のスクロール位置 + センタリング用オフセット
  /// end: 次のインデックスi_x+1要素のスクロール位置 + センタリング用オフセット
  /// （0 <= i < n）
  /// ただし最後の要素の場合、endは タブ要素全体の長さ + センタリング用オフセットになる。
  final List<Tween<double>> _tabOffsets = [];

  final List<Tween<double>> _tabSizeTweens = [];

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
    _totalTabSizeCache = _tabTextSizes.reduce((v, e) => v += e);
    return _totalTabSizeCache;
  }

  double _calculateTabSizeFromIndex(int index) {
    var size = 0.0;
    for (var i = 0; i < index; i++) {
      size += _tabTextSizes[i];
    }
    return size;
  }

  double _centeringOffset(int index) {
    return -(widget.size.width - _tabTextSizes[index]) / 2;
  }

  @override
  void initState() {
    super.initState();

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
        textScaleFactor: widget.textScaleFactor,
        textDirection: widget.textDirection,
      )..layout();
      final calculatedWidth = layoutedText.size.width + widget.tabPadding * 2;
      _tabTextSizes.add(math.min(calculatedWidth, widget.size.width));
      _tabSizesFromIndex.add(_calculateTabSizeFromIndex(i));
    }

    for (var i = 0; i < widget.contentLength; i++) {
      final offsetBegin = _tabSizesFromIndex[i] + _centeringOffset(i);
      final offsetEnd = i == widget.contentLength - 1
          ? _totalTabSize + _centeringOffset(0)
          : _tabSizesFromIndex[i + 1] + _centeringOffset(i + 1);
      _tabOffsets.add(Tween(begin: offsetBegin, end: offsetEnd));

      final sizeBegin = _tabTextSizes[i];
      final sizeEnd = _tabTextSizes[(i + 1) % widget.contentLength];
      _tabSizeTweens.add(Tween(begin: sizeBegin, end: sizeEnd));
    }

    _indicatorSize = ValueNotifier(_tabTextSizes[0]);

    _tabController.addListener(() {
      if (_isTabForceScrolling) return;

      if (_isTabPositionAligned.value) {
        _isTabPositionAligned.value = false;
      }
    });

    _pageController.addListener(() {
      if (_isContentChangingByTab) return;

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
    widget.onTabTap?.call(modIndex);
    widget.onPageChanged?.call(modIndex);

    HapticFeedback.selectionClick();
    _selectedIndex.value = modIndex;
    _isTabPositionAligned.value = true;

    final sizeOnIndex = _calculateTabSizeFromIndex(modIndex);
    final section = rawIndex.isNegative
        ? (rawIndex + 1) ~/ widget.contentLength - 1
        : rawIndex ~/ widget.contentLength;
    final targetOffset = _totalTabSize * section + sizeOnIndex;
    _isTabForceScrolling = true;
    _tabController
        .animateTo(
          targetOffset + _centeringOffset(modIndex),
          duration: _tabAnimationDuration,
          curve: Curves.ease,
        )
        .then((_) => _isTabForceScrolling = false);

    _indicatorAnimation =
        Tween(begin: _indicatorSize.value, end: _tabTextSizes[modIndex])
            .animate(_indicatorAnimationController);
    _indicatorAnimationController.forward(from: 0);

    _isContentChangingByTab = true;
    // 現在のスクロール位置とページインデックスを取得
    final currentOffset = _pageController.offset;
    final currentModIndex =
        (currentOffset ~/ widget.size.width) % widget.contentLength;

    // 選択したページまでの距離を計算する
    // modの境界をまたぐ場合を考慮して、近い方向を指すように正負を調整する
    final move = calculateMoveIndexDistance(
        currentModIndex, modIndex, widget.contentLength);
    final targetPageOffset = currentOffset + move * widget.size.width;

    await _pageController.animateTo(
      targetPageOffset,
      duration: _tabAnimationDuration,
      curve: Curves.ease,
    );

    _isContentChangingByTab = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.tabHeight,
          child: CycledListView.builder(
            scrollDirection: Axis.horizontal,
            controller: _tabController,
            contentCount: widget.contentLength,
            itemBuilder: (context, modIndex, rawIndex) {
              return Material(
                color: widget.backgroundColor,
                child: InkWell(
                  onTap: () => _onTapTab(modIndex, rawIndex),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _selectedIndex,
                    builder: (context, index, _) =>
                        ValueListenableBuilder<bool>(
                      valueListenable: _isTabPositionAligned,
                      builder: (context, tab, _) => _TabContent(
                        isTabPositionAligned: tab,
                        selectedIndex: index,
                        indicatorColor: widget.indicatorColor,
                        tabPadding: widget.tabPadding,
                        modIndex: modIndex,
                        tabBuilder: widget.tabBuilder,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Stack(
          children: [
            if (widget.separator != null)
              Container(
                width: widget.size.width,
                decoration: BoxDecoration(
                  border: Border(bottom: widget.separator!),
                ),
              ),
            ValueListenableBuilder<bool>(
              valueListenable: _isTabPositionAligned,
              builder: (context, value, _) => Visibility(
                visible: value,
                child: _CenteredIndicator(
                  indicatorColor: widget.indicatorColor,
                  size: _indicatorSize,
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
            physics: PageScrollPhysics(),
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
  }) : super(key: key);

  final int modIndex;
  final int selectedIndex;
  final bool isTabPositionAligned;
  final double tabPadding;
  final Color indicatorColor;
  final SelectIndexedTextBuilder tabBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tabPadding,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: selectedIndex == modIndex && !isTabPositionAligned
              ? BorderSide(
                  color: indicatorColor,
                  width: 2.0,
                )
              : BorderSide.none,
        ),
      ),
      child: Center(
        child: tabBuilder(modIndex, selectedIndex == modIndex),
      ),
    );
  }
}

class _CenteredIndicator extends StatelessWidget {
  const _CenteredIndicator({
    Key? key,
    required this.indicatorColor,
    required this.size,
  }) : super(key: key);

  final Color indicatorColor;
  final ValueNotifier<double> size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: size,
      builder: (context, value, _) => Center(
        child: Transform.translate(
          offset: Offset(0.0, -2.0),
          child: Container(
            height: 2.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: indicatorColor,
            ),
            width: value,
          ),
        ),
      ),
    );
  }
}
