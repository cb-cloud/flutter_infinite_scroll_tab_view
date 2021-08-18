import 'package:flutter/material.dart';

import 'inner_infinite_scroll_tab_view.dart';

/// A type of callback to build [Widget] on specified index.
typedef SelectIndexedWidgetBuilder = Widget Function(
    BuildContext context, int index, bool isSelected);

/// A type of callback to build [Text] Widget on specified index.
typedef SelectIndexedTextBuilder = Text Function(int index, bool isSelected);

/// A type of callback to execute processing on tapped tab.
typedef IndexedTapCallback = void Function(int index);

/// A widget for display combo of tabs and pages.
///
/// Internally, the tabs and pages will build as just Scrollable elements like
/// `ListView`. But these have massive index range from [double.negativeInfinity]
/// to [double.infinity], so that these can scroll infinitely.
class InfiniteScrollTabView extends StatelessWidget {
  /// Creates a tab view widget that can scroll infinitely.
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
    this.indicatorHeight,
    this.tabHeight = 44.0,
    this.tabPadding = 12.0,
    this.size,
    this.forceFixedTabWidth = false,
    this.fixedTabWidthFraction = 0.7,
  }) : super(key: key);

  /// A length of tabs and pages.
  ///
  /// This value is shared between tabs and pages, so those must have same
  /// content length.
  ///
  /// Otherwise, if this value is less than tab contents, [tabBuilder] output
  /// will be repeated in [contentLength].
  final int contentLength;

  /// A callback for build tab contents that can scroll infinitely.
  ///
  /// This must return [Text] Widget as specified by the type.
  ///
  /// See: [SelectIndexedTextBuilder]
  /// `index` is modulo number of real index by [contentLength].
  /// `isSelected` is the state that indicates whether the tab is selected or not.
  final SelectIndexedTextBuilder tabBuilder;

  /// A callback for build page contents that can scroll infinitely.
  ///
  /// See: [SelectIndexedWidgetBuilder]
  /// `index` is modulo number of real index by [contentLength].
  /// `isSelected` is the state that indicates whether the tab is selected or not.
  final SelectIndexedWidgetBuilder pageBuilder;

  /// A callback for tapped tab element.
  ///
  /// `index` is modulo number of real index by [contentLength].
  final IndexedTapCallback? onTabTap;

  /// The border specification that displays between tabs and pages.
  ///
  /// If this is null, any border line will not be displayed.
  final BorderSide? separator;

  /// The color of tab list.
  ///
  /// If this is null, the list background color will become [Material] default.
  final Color? backgroundColor;

  /// A callback on changed selected page.
  ///
  /// This will called by both tab tap occurred and page swipe occurred.
  final ValueChanged<int>? onPageChanged;

  /// The color of indicator that shows selected page.
  ///
  /// Defaults to [Colors.pinkAccent], and must not be null.
  final Color indicatorColor;

  /// The height of indicator.
  ///
  /// If this is null, the indicator height is aligned to [separator] height, or
  /// it also null, then fallbacks to 2.0.
  ///
  /// This must 1.0 or higher.
  final double? indicatorHeight;

  /// The height of tab contents.
  ///
  /// Defaults to 44.0.
  final double tabHeight;

  /// The padding value of each tab contents.
  ///
  /// Defaults to 12.0.
  /// This value sets as horizontal padding. For example, specify 12.0 then
  /// the tabs will have padding as `EdgeInsets.symmetric(horizontal: 12.0)`.
  final double tabPadding;

  /// The size constraint of this widget.
  ///
  /// If this is null, then `MediaQuery.of(context).size` is used as default.
  /// This value should specify only in some rare case, testing or something
  /// like that.
  /// Internally this is only used for get page width, but this value determines
  /// entire widget's width.
  final Size? size;

  final bool forceFixedTabWidth;
  final double fixedTabWidthFraction;

  @override
  Widget build(BuildContext context) {
    if (indicatorHeight != null) {
      assert(indicatorHeight! >= 1.0);
    }

    return InnerInfiniteScrollTabView(
      size: MediaQuery.of(context).size,
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
      indicatorHeight: indicatorHeight,
      defaultLocale: Localizations.localeOf(context),
      tabHeight: tabHeight,
      tabPadding: tabPadding,
      forceFixedTabWidth: forceFixedTabWidth,
      fixedTabWidthFraction: fixedTabWidthFraction,
    );
  }
}
