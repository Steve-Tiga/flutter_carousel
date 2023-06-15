import 'dart:async';
import 'package:flutter/material.dart';

class SwiperController extends ChangeNotifier {
  SwiperController({this.initialPage = 0});

  final int initialPage;

  int get index => _state.getIndex();

  double? get offset => _state._pageController?.offset;

  _SwiperState? _swiperState;

  _SwiperState get _state {
    assert(_swiperState != null,
    "SwiperController cannot be accessed before a Swiper is built with it");
    return _swiperState!;
  }

  void start() => _state.start();
  void stop() => _state.stop();

  Future<void> animateToPage(
      int page, {
        required Duration duration,
        required Curve curve,
      }) {
    return _state.animateToPage(
      page < 0 ? 0 : page,
      duration: duration,
      curve: curve,
    );
  }

  Future<void> nextPage({
    required Duration duration,
    required Curve curve,
  }) {
    return animateToPage(_state._index + 1, duration: duration, curve: curve);
  }

  Future<void> previousPage({
    required Duration duration,
    required Curve curve,
  }) {
    return animateToPage(
      _state._index == 0 ? _state.widget.childCount - 1 : _state._index - 1,
      duration: duration,
      curve: curve,
    );
  }

  void _attach(_SwiperState state) => _swiperState = state;

  void _detach() => _swiperState = null;
}

abstract class SwiperIndicator {
  Widget build(BuildContext context, int index, int itemCount);
}

class RectangleSwiperIndicator extends _SwiperIndicator {
  RectangleSwiperIndicator({
    EdgeInsetsGeometry? padding,
    double spacing = 4.0,
    double itemWidth = 16.0,
    double itemHeight = 2.0,
    Color itemColor = Colors.white70,
    Color itemActiveColor = Colors.black,
  }) : super(
    padding: padding,
    spacing: spacing,
    itemColor: itemColor,
    itemWidth: itemWidth,
    itemHeight: itemHeight,
    itemActiveColor: itemActiveColor,
    itemShape: BoxShape.rectangle,
  );
}

class CircleSwiperIndicator extends _SwiperIndicator {
  CircleSwiperIndicator({
    EdgeInsetsGeometry? padding,
    double spacing = 6.0,
    double radius = 3.5,
    Color itemColor = Colors.white70,
    Color itemActiveColor = Colors.black,
  }) : super(
    padding: padding,
    spacing: spacing,
    itemColor: itemColor,
    itemWidth: radius * 2,
    itemHeight: radius * 2,
    itemActiveColor: itemActiveColor,
    itemShape: BoxShape.circle,
  );
}

class _SwiperIndicator implements SwiperIndicator {
  _SwiperIndicator({
    this.spacing = 0.0,
    this.itemColor = Colors.white70,
    this.itemActiveColor,
    required this.itemWidth,
    required this.itemHeight,
    required this.itemShape,
    this.padding,
  });
  final double spacing;
  final Color itemColor;
  final Color? itemActiveColor;
  final double itemWidth;
  final double itemHeight;
  final BoxShape itemShape;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, int index, int itemCount) {
    if (itemCount == 1) return const SizedBox(width: .0, height: .0);

    var children = List.generate(itemCount, (_index) {
      Color color = itemColor;
      if (_index == index) {
        color = itemActiveColor ?? Theme.of(context).colorScheme.secondary;
      }
      return Container(
        width: itemWidth,
        height: itemHeight,
        decoration: BoxDecoration(color: color, shape: itemShape),
      );
    });
    return Padding(
      padding: padding ?? const EdgeInsets.all(10.0),
      child: Wrap(
        runSpacing: spacing,
        spacing: spacing,
        children: children,
      ),
    );
  }
}

class _Indicator extends StatefulWidget {
  const _Indicator({
    Key? key,
    required this.initPage,
    required this.itemCount,
    required this.indicator,
  }) : super(key: key);

  @override
  __IndicatorState createState() => __IndicatorState();

  final SwiperIndicator indicator;
  final int itemCount;
  final int initPage;
}

class __IndicatorState extends State<_Indicator> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initPage;
  }

  update(int index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.indicator.build(context, _index, widget.itemCount);
  }
}

class Swiper extends StatefulWidget {
  Swiper({
    Key? key,
    this.direction = Axis.horizontal,
    this.autoStart = false,
    this.controller,
    this.indicator,
    this.speed = 300,
    this.interval = const Duration(seconds: 3),
    this.circular = true,
    this.reverse = false,
    this.indicatorAlignment = AlignmentDirectional.bottomCenter,
    this.viewportFraction = 1.0,
    this.onChanged,
    required this.children,
  })  : childCount = children!.length,
        itemBuilder = ((context, index) => children[index]),
        super(key: key);

  const Swiper.builder({
    Key? key,
    this.direction = Axis.horizontal,
    required this.childCount,
    required this.itemBuilder,
    this.autoStart = false,
    this.controller,
    this.indicator,
    this.speed = 300,
    this.interval = const Duration(seconds: 3),
    this.circular = true,
    this.reverse = false,
    this.indicatorAlignment = AlignmentDirectional.bottomCenter,
    this.viewportFraction = 1.0,
    this.onChanged,
  })  : children = null,
        super(key: key);

  final Axis direction;
  final bool reverse;

  final ValueChanged<int>? onChanged;
  final SwiperController? controller;
  final IndexedWidgetBuilder itemBuilder;
  final int childCount;
  final int speed;
  final bool autoStart;
  final SwiperIndicator? indicator;
  final AlignmentDirectional indicatorAlignment;
  final bool circular;
  final Duration interval;
  final double viewportFraction;

  final List<Widget>? children;

  @override
  _SwiperState createState() => _SwiperState();
}

class _SwiperState extends State<Swiper>
    with SingleTickerProviderStateMixin<Swiper> {
  PageController? _pageController;
  late int _index;
  Timer? _timer;
  bool _autoPlay = false;
  final _globalKey = GlobalKey<__IndicatorState>();
  bool _animateToPage = false;

  int getIndex() {
    return _index % widget.childCount;
  }

  @override
  void initState() {
    super.initState();
    _initController();
    if (widget.autoStart) start();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(Swiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller?.initialPage != widget.controller?.initialPage ||
        oldWidget.viewportFraction != widget.viewportFraction ||
        oldWidget.circular != widget.circular) {
      _initController(_index);
    }

    if (oldWidget.autoStart != widget.autoStart) {
      widget.autoStart ? start() : stop();
    }
  }

  start() {
    _autoPlay = true;
    _start();
  }

  stop() {
    _autoPlay = false;
    _timer?.cancel();
  }

  void _initController([int? index]) {
    _pageController?.dispose();
    _index = index ?? widget.controller?.initialPage ?? 0;

    if (widget.circular) {
      _index = widget.childCount + _index;
    } else {
      _index = getIndex();
    }

    _pageController = PageController(
      initialPage: _index,
      viewportFraction: widget.viewportFraction,
    );
  }

  void _start() {
    if (!_autoPlay || widget.childCount < 2) return;
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (timer) {
      animateToPage(
        widget.circular ? _index + 1 : (_index + 1) % widget.childCount,
        duration: Duration(milliseconds: widget.speed),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> animateToPage(
      int page, {
        required Duration duration,
        required Curve curve,
      }) async {
    if (widget.childCount < 2) return;

    int dest = page % widget.childCount;

    //不循环
    if (!widget.circular) {
      var cur = getIndex();
      page = dest;
      var last = widget.childCount - 1;
      if (page == cur ||
          (cur == 0 && page == last) ||
          //到最后一个page后，如果没有自动播放则什么也不做，否则需要回到第一个page
          (!_autoPlay && cur == last && page == 0)) {
        return;
      }
    } else {
      int distance = dest - getIndex();
      //检查是目标页是否当前页
      if (distance == 0) {
        return;
      }
    }

    _animateToPage = true;

    return _pageController
        ?.animateToPage(page, duration: duration, curve: curve)
        .then((e) {
      _globalKey.currentState?.update(getIndex());
      if (widget.onChanged != null) widget.onChanged!(dest);
      _animateToPage = false;
    });
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _pageController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (widget.circular && index < widget.childCount) {
      _index = widget.childCount + index;
      _pageController!.jumpToPage(_index);
      return;
    } else {
      _index = index;
    }
    _globalKey.currentState?.update(getIndex());
    if (!_animateToPage && widget.onChanged != null) {
      widget.onChanged!(getIndex());
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    children.add(PageView.builder(
      //循环方式改变后要重新build，为了确保index的初始值正确
      key: ValueKey(widget.circular),
      scrollDirection: widget.direction,
      reverse: widget.reverse,
      itemCount:
      widget.circular && widget.childCount != 1 ? null : widget.childCount,
      onPageChanged: _onPageChanged,
      controller: _pageController,
      itemBuilder: (context, index) {
        return widget.itemBuilder(context, index % widget.childCount);
      },
    ));

    if (widget.indicator != null) {
      var indicator = _Indicator(
        key: _globalKey,
        initPage: getIndex(),
        itemCount: widget.childCount,
        indicator: widget.indicator!,
      );
      children.add(Positioned(
        child: indicator,
      ));
    }

    return Listener(
      onPointerDown: (event) => _timer?.cancel(),
      onPointerCancel: (event) => _start(),
      onPointerUp: (event) => _start(),
      child: MouseRegion(
        onEnter: (event) => _timer?.cancel(),
        onExit: (event) => _start(),
        child: Stack(alignment: widget.indicatorAlignment, children: children),
      ),
    );
  }
}