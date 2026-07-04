import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../navigation/app_route_observer.dart';

class RouteAwareAssetVideo extends StatefulWidget {
  const RouteAwareAssetVideo({
    super.key,
    required this.videoAsset,
    required this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.startDelay = const Duration(milliseconds: 600),
    this.disableVideoOnWeb = true,
  });

  final String videoAsset;
  final String fallbackAsset;
  final BoxFit fit;
  final Duration startDelay;
  final bool disableVideoOnWeb;

  @override
  State<RouteAwareAssetVideo> createState() => _RouteAwareAssetVideoState();
}

class _RouteAwareAssetVideoState extends State<RouteAwareAssetVideo>
    with RouteAware, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  ModalRoute<void>? _route;
  Timer? _startTimer;
  bool _appResumed = true;
  bool _routeVisible = true;
  bool _initializing = false;

  bool get _shouldPlay => _appResumed && _routeVisible;

  bool _shouldUseFallbackOnly(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final disableAnimations = mediaQuery?.disableAnimations ?? false;
    if (disableAnimations) return true;
    if (widget.disableVideoOnWeb && kIsWeb) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void> && route != _route) {
      if (_route != null) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
    _syncPlaybackState();
  }

  @override
  void didPush() => _syncPlaybackState();

  @override
  void didPopNext() {
    _routeVisible = true;
    _syncPlaybackState();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncPlaybackState();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _syncPlaybackState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    _syncPlaybackState();
  }

  void _syncPlaybackState() {
    if (_shouldUseFallbackOnly(context)) {
      _startTimer?.cancel();
      return;
    }
    final controller = _controller;
    if (!_shouldPlay) {
      _startTimer?.cancel();
      if (controller != null && controller.value.isInitialized) {
        controller.pause();
      }
      return;
    }

    if (controller != null && controller.value.isInitialized) {
      controller.play();
      return;
    }

    if (_initializing) return;
    _startTimer?.cancel();
    _startTimer = Timer(widget.startDelay, _initializeVideo);
  }

  Future<void> _initializeVideo() async {
    if (!mounted ||
        !_shouldPlay ||
        _controller != null ||
        _initializing ||
        _shouldUseFallbackOnly(context)) {
      return;
    }

    _initializing = true;
    final controller = VideoPlayerController.asset(
      widget.videoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller
        ..setLooping(true)
        ..setVolume(0);
      if (_shouldPlay) {
        await controller.play();
      }
      setState(() {
        _controller = controller;
      });
    } catch (_) {
      await controller.dispose();
    } finally {
      _initializing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _startTimer?.cancel();
    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldUseFallbackOnly(context)) {
      return Image.asset(
        widget.fallbackAsset,
        fit: widget.fit,
        filterQuality: FilterQuality.low,
      );
    }
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: RepaintBoundary(
            child: VideoPlayer(controller),
          ),
        ),
      );
    }

    return Image.asset(
      widget.fallbackAsset,
      fit: widget.fit,
      filterQuality: FilterQuality.low,
    );
  }
}
