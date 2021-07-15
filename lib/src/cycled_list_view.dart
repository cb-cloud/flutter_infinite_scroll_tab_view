import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef ModuloIndexedWidgetBuilder = Widget Function(
    BuildContext context, int modIndex, int rawIndex);

class CycledListView extends StatefulWidget {
  /// See [ListView.builder]
  const CycledListView.builder({
    Key? key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.physics,
    this.padding,
    this.itemExtent,
    required this.itemBuilder,
    required this.contentCount,
    this.itemCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.anchor = 0.0,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  /// See: [ScrollView.scrollDirection]
  final Axis scrollDirection;

  /// See: [ScrollView.reverse]
  final bool reverse;

  /// See: [ScrollView.controller]
  final CycledScrollController? controller;

  /// See: [ScrollView.physics]
  final ScrollPhysics? physics;

  /// See: [BoxScrollView.padding]
  final EdgeInsets? padding;

  /// See: [ListView.builder]
  final ModuloIndexedWidgetBuilder itemBuilder;

  /// See: [SliverChildBuilderDelegate.childCount]
  final int? itemCount;

  /// See: [ListView.itemExtent]
  final double? itemExtent;

  /// See: [ScrollView.cacheExtent]
  final double? cacheExtent;

  /// See: [ScrollView.anchor]
  final double anchor;

  /// See: [SliverChildBuilderDelegate.addAutomaticKeepAlives]
  final bool addAutomaticKeepAlives;

  /// See: [SliverChildBuilderDelegate.addRepaintBoundaries]
  final bool addRepaintBoundaries;

  /// See: [SliverChildBuilderDelegate.addSemanticIndexes]
  final bool addSemanticIndexes;

  /// See: [ScrollView.dragStartBehavior]
  final DragStartBehavior dragStartBehavior;

  /// See: [ScrollView.keyboardDismissBehavior]
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// See: [ScrollView.restorationId]
  final String? restorationId;

  /// See: [ScrollView.clipBehavior]
  final Clip clipBehavior;

  final int contentCount;

  @override
  _CycledListViewState createState() => _CycledListViewState();
}

class _CycledListViewState extends State<CycledListView> {
  CycledScrollController? _controller;

  CycledScrollController get _effectiveController =>
      widget.controller ?? _controller!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = CycledScrollController(initialScrollOffset: 0.0);
    }
  }

  @override
  void didUpdateWidget(CycledListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      _controller = CycledScrollController(initialScrollOffset: 0.0);
    } else if (widget.controller != null && oldWidget.controller == null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> slivers = _buildSlivers(context);
    final AxisDirection axisDirection = _getDirection(context);
    final scrollPhysics =
        widget.physics ?? const AlwaysScrollableScrollPhysics();
    return Scrollable(
      axisDirection: axisDirection,
      controller: _effectiveController,
      physics: scrollPhysics,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        // Register listener to jump greater page when offset is less than threshold.
        offset.addListener(() {
          if (!(offset is _InfiniteScrollPosition)) return;
          if (offset.pixels < 0.0) {
            offset._forcePixels(_effectiveController.initialScrollOffset);
          }
        });

        return Viewport(
          axisDirection: axisDirection,
          anchor: widget.anchor,
          offset: offset,
          slivers: slivers,
          cacheExtent: widget.cacheExtent,
        );
      },
    );
  }

  AxisDirection _getDirection(BuildContext context) {
    return getAxisDirectionFromAxisReverseAndDirectionality(
        context, widget.scrollDirection, widget.reverse);
  }

  List<Widget> _buildSlivers(BuildContext context) {
    final itemExtent = widget.itemExtent;
    return <Widget>[
      (itemExtent != null)
          ? SliverFixedExtentList(
              delegate: positiveChildrenDelegate,
              itemExtent: itemExtent,
            )
          : SliverList(
              delegate: positiveChildrenDelegate,
            ),
    ];
  }

  SliverChildDelegate get positiveChildrenDelegate {
    final itemCount = widget.itemCount;
    return SliverChildBuilderDelegate(
      (context, index) =>
          widget.itemBuilder(context, index % widget.contentCount, index),
      childCount: itemCount,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(EnumProperty<Axis>('scrollDirection', widget.scrollDirection));
    properties.add(FlagProperty('reverse',
        value: widget.reverse, ifTrue: 'reversed', showName: true));
    properties.add(DiagnosticsProperty<ScrollController>(
        'controller', widget.controller,
        showName: false, defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollPhysics>('physics', widget.physics,
        showName: false, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>(
        'padding', widget.padding,
        defaultValue: null));
    properties.add(
        DoubleProperty('itemExtent', widget.itemExtent, defaultValue: null));
    properties.add(
        DoubleProperty('cacheExtent', widget.cacheExtent, defaultValue: null));
  }
}

/// Same as a [ScrollController] except it provides [ScrollPosition] objects with infinite bounds.
class CycledScrollController extends ScrollController {
  /// Creates a new [CycledScrollController]
  CycledScrollController({
    required this.initialScrollOffset,
    bool keepScrollOffset = true,
    String? debugLabel,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  final double initialScrollOffset;

  ScrollDirection get currentScrollDirection => position.userScrollDirection;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition? oldPosition) {
    return _InfiniteScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _InfiniteScrollPosition extends ScrollPositionWithSingleContext {
  _InfiniteScrollPosition({
    required ScrollPhysics physics,
    required ScrollContext context,
    double? initialPixels = 0.0,
    bool keepScrollOffset = true,
    ScrollPosition? oldPosition,
    String? debugLabel,
  }) : super(
          physics: physics,
          context: context,
          initialPixels: initialPixels,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  void _forcePixels(double value) {
    super.forcePixels(value);
  }

  @override
  double get minScrollExtent => double.negativeInfinity;

  @override
  double get maxScrollExtent => double.infinity;
}
