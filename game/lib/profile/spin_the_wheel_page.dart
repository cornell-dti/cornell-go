import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:provider/provider.dart';

class SpinTheWheelPage extends StatefulWidget {
  const SpinTheWheelPage({
    super.key,
    this.onSpinSessionStarted,
    this.onSpinResultClosed,
  });

  /// Fired as soon as the user starts a spin, before the server marks them on cooldown.
  final VoidCallback? onSpinSessionStarted;

  /// After the result dialog closes (Equip Now or X), or if the spin errors.
  final VoidCallback? onSpinResultClosed;

  @override
  State<SpinTheWheelPage> createState() => _SpinTheWheelPageState();
}

class _SpinTheWheelPageState extends State<SpinTheWheelPage>
    with SingleTickerProviderStateMixin {
  List<BearItemDto> _wheelItems = [];
  bool _canSpin = false;
  int _remainingCooldownSeconds = 0;
  bool _isLoading = true;
  bool _isSpinning = false;

  late final AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentRotation = 0;

  StreamSubscription<SpinAvailabilityDto>? _availabilitySub;
  StreamSubscription<SpinWheelItemsDto>? _wheelItemsSub;
  StreamSubscription<SpinResultDto>? _spinResultSub;
  StreamSubscription<UpdateErrorDto>? _errorSub;
  Timer? _countdownTimer;

  final _spinResultCompleter = StreamController<SpinResultDto>.broadcast();

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _spinAnimation = AlwaysStoppedAnimation(0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStreamsAndLoad();
    });
  }

  @override
  void dispose() {
    _availabilitySub?.cancel();
    _wheelItemsSub?.cancel();
    _spinResultSub?.cancel();
    _errorSub?.cancel();
    _countdownTimer?.cancel();
    _spinResultCompleter.close();
    _spinController.dispose();
    super.dispose();
  }

  void _initStreamsAndLoad() {
    final apiClient = context.read<ApiClient>();
    final server = apiClient.serverApi;
    if (server == null) return;

    _availabilitySub ??=
        apiClient.clientApi.updateSpinAvailabilityDataStream.listen((data) {
      setState(() {
        _canSpin = data.canSpin;
        _remainingCooldownSeconds = data.remainingCooldownSeconds;
      });
      _startOrStopCountdown();
    });

    _wheelItemsSub ??=
        apiClient.clientApi.updateSpinWheelItemsDataStream.listen((data) {
      setState(() {
        _wheelItems = data.items.take(8).toList();
        _isLoading = false;
      });
    });

    _spinResultSub ??= apiClient.clientApi.updateSpinResultDataStream.listen((
      data,
    ) {
      _spinResultCompleter.add(data);
    });

    _errorSub ??= apiClient.clientApi.updateErrorDataStream.listen((data) {
      if (!mounted || data.message.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data.message)),
      );
    });

    server.requestSpinAvailability(RequestSpinAvailabilityDto());
    server.requestSpinWheelItems(RequestSpinWheelItemsDto());
  }

  void _startOrStopCountdown() {
    _countdownTimer?.cancel();
    if (_canSpin || _remainingCooldownSeconds <= 0) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingCooldownSeconds <= 0) {
        timer.cancel();
        setState(() {
          _canSpin = true;
        });
        return;
      }
      setState(() {
        _remainingCooldownSeconds -= 1;
      });
    });
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  Future<void> _spin() async {
    if (_isSpinning || !_canSpin || _wheelItems.isEmpty) return;

    final apiClient = context.read<ApiClient>();
    final server = apiClient.serverApi;
    if (server == null) return;

    setState(() {
      _isSpinning = true;
    });
    widget.onSpinSessionStarted?.call();

    // Immediate visual feedback on tap so the wheel starts moving right away.
    await _animateByRadians(
      radians: 2 * math.pi * 1.5,
      durationMs: 700,
      curve: Curves.easeIn,
    );

    server.spinWheel(SpinWheelDto());

    SpinResultDto result;
    try {
      result = await _spinResultCompleter.stream.first.timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSpinning = false;
      });
      widget.onSpinResultClosed?.call();
      context
          .read<ApiClient>()
          .serverApi
          ?.requestSpinAvailability(RequestSpinAvailabilityDto());
      return;
    }

    final wonIndex =
        _wheelItems.indexWhere((item) => item.id == result.wonItem.id);
    if (wonIndex < 0) {
      setState(() {
        _wheelItems = [result.wonItem, ..._wheelItems].take(8).toList();
      });
    }
    final targetIndex =
        _wheelItems.indexWhere((item) => item.id == result.wonItem.id);
    await _animateToIndex(targetIndex < 0 ? 0 : targetIndex);

    if (!mounted) return;
    setState(() {
      _isSpinning = false;
      _canSpin = false;
      _remainingCooldownSeconds = result.cooldownSeconds;
    });
    _startOrStopCountdown();
    _showWinDialog(result.wonItem);
  }

  Future<void> _animateByRadians({
    required double radians,
    required int durationMs,
    required Curve curve,
  }) async {
    final finalRotation = _currentRotation + radians;
    _spinController.duration = Duration(milliseconds: durationMs);
    _spinAnimation = Tween<double>(
      begin: _currentRotation,
      end: finalRotation,
    ).animate(CurvedAnimation(parent: _spinController, curve: curve));

    setState(() {});
    await _spinController.forward(from: 0);
    _currentRotation = finalRotation;
  }

  Future<void> _animateToIndex(int index) async {
    final segmentCount = _wheelItems.isEmpty ? 8 : _wheelItems.length;
    final segmentAngle = (2 * math.pi) / segmentCount;
    final targetOffset = (2 * math.pi - (index * segmentAngle)) % (2 * math.pi);
    final currentOffset = _currentRotation % (2 * math.pi);
    final delta =
        (targetOffset - currentOffset + (2 * math.pi)) % (2 * math.pi);
    final finalRotation = _currentRotation + (6 * 2 * math.pi) + delta;

    _spinController.duration = const Duration(milliseconds: 4200);
    _spinAnimation = Tween<double>(
      begin: _currentRotation,
      end: finalRotation,
    ).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );

    setState(() {});
    await _spinController.forward(from: 0);
    _currentRotation = finalRotation;
  }

  void _showWinDialog(BearItemDto wonItem) {
    void onDismissed() {
      if (!mounted) return;
      widget.onSpinResultClosed?.call();
      context
          .read<ApiClient>()
          .serverApi
          ?.requestSpinAvailability(RequestSpinAvailabilityDto());
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'You Won',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      wonItem.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFED5656),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Image.asset('assets/${wonItem.assetKey}.png',
                          fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: GestureDetector(
                        onTap: () {
                          context.read<ApiClient>().serverApi?.equipBearItem(
                                EquipBearItemDto(
                                    slot: wonItem.slot, itemId: wonItem.id),
                              );
                          Navigator.pop(dialogContext);
                        },
                        child: SvgPicture.asset(
                          'assets/wheel/equipnow.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: SvgPicture.asset(
                    'assets/wheel/close.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => onDismissed());
  }

  @override
  Widget build(BuildContext context) {
    final wheelItems = _wheelItems;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFED5656),
        foregroundColor: Colors.white,
        title: const Text('Spin the Wheel'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              if (_isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (wheelItems.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No wardrobe items available yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<ApiClient>()
                                .serverApi
                                ?.requestSpinWheelItems(
                                  RequestSpinWheelItemsDto(),
                                );
                          },
                          child: const Text('Refresh Items'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/wheel/spinthewheel.svg',
                          height: 120,
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(top: 56, bottom: 0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _spinAnimation,
                                builder: (context, child) {
                                  final a = _spinAnimation.value;
                                  return Transform.rotate(
                                    angle: a,
                                    child: _WheelWidget(
                                      items: wheelItems,
                                      rotation: a,
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: -58,
                                child: SvgPicture.asset('assets/wheel/Pointer.svg',
                                    height: 64),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              if (_canSpin)
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _isSpinning ? null : _spin,
                    child: Opacity(
                      opacity: _isSpinning ? 0.6 : 1,
                      child: SvgPicture.asset(
                        'assets/wheel/spinbutton.svg',
                        height: 102,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8F8F8F),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Wait ${_formatDuration(_remainingCooldownSeconds)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

int _segmentIndexAtPointer(int segmentCount, double wheelRotation) {
  if (segmentCount <= 0) return 0;
  final sa = (2 * math.pi) / segmentCount;
  // Pointer at 12 o'clock: bisector of segment j in local is -pi/2 + j*sa; after turn R, j*sa ≡ -R (mod 2pi).
  var t = -wheelRotation;
  t %= 2 * math.pi;
  if (t < 0) t += 2 * math.pi;
  return (t / sa + 1e-9).floor() % segmentCount;
}

class _WheelWidget extends StatelessWidget {
  const _WheelWidget({required this.items, required this.rotation});

  final List<BearItemDto> items;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    const size = 300.0;
    final n = items.length;
    final selected = _segmentIndexAtPointer(n, rotation);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _WheelPainter(
              segmentCount: n,
              selectedIndex: selected,
            ),
          ),
          ...List.generate(items.length, (index) {
            final angle =
                (-math.pi / 2) + (2 * math.pi * index / items.length);
            final radius = size * 0.31;
            return Transform.translate(
              offset:
                  Offset(radius * math.cos(angle), radius * math.sin(angle)),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Image.asset('assets/${items[index].assetKey}.png',
                    fit: BoxFit.contain),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.segmentCount, required this.selectedIndex});

  final int segmentCount;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / segmentCount;
    final fillColors = [
      const Color(0xFFFFAA5B),
      const Color(0xFFED5656),
    ];
    for (int i = 0; i < segmentCount; i++) {
      final path = Path()..moveTo(center.dx, center.dy);
      final start = (-math.pi / 2 - segmentAngle / 2) + (i * segmentAngle);
      path.arcTo(Rect.fromCircle(center: center, radius: radius), start,
          segmentAngle, false);
      path.close();

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColors[i % fillColors.length];
      canvas.drawPath(path, paint);

      if (i == selectedIndex) {
        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFFF0300);
        canvas.drawPath(path, stroke);
      }
    }

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0xFFED5656);
    canvas.drawCircle(center, radius, border);
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFFED5656));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.segmentCount != segmentCount ||
      oldDelegate.selectedIndex != selectedIndex;
}
