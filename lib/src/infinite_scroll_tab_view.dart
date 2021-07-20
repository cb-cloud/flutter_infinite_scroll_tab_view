import 'package:flutter/material.dart';

import 'inner_infinite_scroll_tab_view.dart';

typedef SelectIndexedWidgetBuilder = Widget Function(
    BuildContext context, int index, bool isSelected);

typedef SelectIndexedTextBuilder = Text Function(int index, bool isSelected);

typedef IndexedTapCallback = void Function(int index);

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
      builder: (context, constraint) => InnerInfiniteScrollTabView(
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
