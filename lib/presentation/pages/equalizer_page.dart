import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/presentation/services/music_player_service.dart';

/// Sound-shaping screen: a real equalizer (Android), presets, and the
/// Speed / Enhance / Sleep / Share controls. Opened from Now Playing.
class EqualizerPage extends StatefulWidget {
  final MusicPlayerService playerService;

  const EqualizerPage({super.key, required this.playerService});

  static Future<void> open(
    BuildContext context,
    MusicPlayerService playerService,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EqualizerPage(playerService: playerService),
      ),
    );
  }

  @override
  State<EqualizerPage> createState() => _EqualizerPageState();
}

class _BandVM {
  final double centerHz;
  double gain;
  final AndroidEqualizerBand? real;
  _BandVM(this.centerHz, this.gain, [this.real]);

  Future<void> apply(double g) async {
    gain = g;
    try {
      await real?.setGain(g);
    } catch (_) {}
  }
}

const _presets = <({String name, IconData icon})>[
  (name: 'Balanced', icon: Icons.volume_up_outlined),
  (name: 'Bass boost', icon: Icons.graphic_eq),
  (name: 'Vocal', icon: Icons.tune),
  (name: 'Electronic', icon: Icons.music_note_outlined),
  (name: 'Acoustic', icon: Icons.equalizer),
  (name: 'Pop', icon: Icons.queue_music),
];

class _EqualizerPageState extends State<EqualizerPage> {
  List<_BandVM> _bands = [];
  double _min = -15, _max = 15;
  bool _enabled = true;
  bool _loading = true;
  String _preset = 'Acoustic';

  MusicPlayerService get _svc => widget.playerService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      try {
        final p = await _svc.equalizer.parameters
            .timeout(const Duration(seconds: 2));
        _min = p.minDecibels;
        _max = p.maxDecibels;
        _bands = p.bands
            .map((b) => _BandVM(b.centerFrequency, b.gain, b))
            .toList();
      } catch (_) {
        _bands = _mockBands();
      }
    } else {
      _bands = _mockBands();
    }
    await _svc.setEqualizerEnabled(_enabled);
    if (mounted) setState(() => _loading = false);
  }

  List<_BandVM> _mockBands() {
    const freqs = <double>[31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
    return [for (final f in freqs) _BandVM(f, 0)];
  }

  void _setGain(int i, double g) {
    final v = g.clamp(_min, _max);
    setState(() {
      _bands[i].gain = v;
      _preset = ''; // manual edit clears the preset selection
    });
    _bands[i].apply(v);
  }

  void _applyPreset(String name) {
    setState(() {
      _preset = name;
      for (final b in _bands) {
        b.gain = _presetGain(name, b.centerHz, _min, _max);
      }
    });
    for (final b in _bands) {
      b.apply(b.gain);
    }
  }

  double _presetGain(String preset, double hz, double min, double max) {
    double n; // -1..1 fraction of range
    switch (preset) {
      case 'Bass boost':
        n = hz <= 80 ? 1.0 : hz <= 250 ? 0.6 : hz <= 500 ? 0.25 : 0.0;
      case 'Vocal':
        n = (hz >= 400 && hz <= 3000)
            ? 0.6
            : hz < 150 ? -0.2 : hz > 6000 ? -0.1 : 0.1;
      case 'Electronic':
        n = hz <= 120 ? 0.85 : hz >= 6000 ? 0.6 : (hz >= 400 && hz <= 2000) ? -0.3 : 0.0;
      case 'Acoustic':
        n = hz <= 120 ? 0.3 : (hz >= 1000 && hz <= 4000) ? 0.45 : 0.1;
      case 'Pop':
        n = (hz >= 500 && hz <= 3000) ? 0.4 : hz <= 120 ? 0.2 : hz >= 8000 ? 0.3 : 0.0;
      default: // Balanced
        n = 0;
    }
    final db = n >= 0 ? n * max : n * min.abs();
    return db.clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _topBar(),
                  const SizedBox(height: 12),
                  _eqCard(),
                  const SizedBox(height: 16),
                  _actionsCard(),
                ],
              ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _circleBtn(Icons.arrow_back_ios_new, () => Navigator.of(context).pop()),
        const Spacer(),
        const Text(
          'Sound',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _eqCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241A33), Color(0xFF17131C)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Equalizer',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _preset.isEmpty ? 'Custom' : _preset,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.elevated,
                onChanged: (v) {
                  setState(() => _enabled = v);
                  _svc.setEqualizerEnabled(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: _enabled ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !_enabled,
              child: _EqGraph(
                bands: _bands,
                min: _min,
                max: _max,
                onChanged: _setGain,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'PRESETS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.3,
            children: [
              for (final p in _presets)
                _presetCard(p.name, p.icon, _preset == p.name),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetCard(String name, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => _applyPreset(name),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _svc.speed,
            builder: (context, sp, _) => _action(
              Icons.speed,
              'Speed',
              subtitle: '${sp.toStringAsFixed(sp % 1 == 0 ? 0 : 2)}×',
              highlight: sp != 1.0,
              onTap: _showSpeedSheet,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _svc.enhanceEnabled,
            builder: (context, on, _) => _action(
              Icons.auto_awesome,
              'Enhance',
              highlight: on,
              onTap: () => _svc.setEnhance(!on),
            ),
          ),
          ValueListenableBuilder<Duration?>(
            valueListenable: _svc.sleepRemaining,
            builder: (context, rem, _) => _action(
              Icons.power_settings_new,
              'Sleep',
              subtitle: rem == null ? null : _fmt(rem),
              highlight: rem != null,
              onTap: _showSleepSheet,
            ),
          ),
          _action(Icons.ios_share, 'Share', onTap: _share),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label,
      {String? subtitle, bool highlight = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlight
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: highlight
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(icon,
                size: 20,
                color: highlight ? AppColors.accent : AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle ?? label,
            style: TextStyle(
              color: highlight ? AppColors.accent : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Action handlers ---------------------------------------------------

  void _showSpeedSheet() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    _sheet(
      title: 'Playback speed',
      children: [
        for (final s in speeds)
          ValueListenableBuilder<double>(
            valueListenable: _svc.speed,
            builder: (context, cur, _) => ListTile(
              title: Text('${s.toStringAsFixed(s % 1 == 0 ? 0 : 2)}×',
                  style: const TextStyle(color: AppColors.textPrimary)),
              trailing: cur == s
                  ? const Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () {
                _svc.setSpeed(s);
                Navigator.of(context).pop();
              },
            ),
          ),
      ],
    );
  }

  void _showSleepSheet() {
    const minutes = [15, 30, 45, 60];
    _sheet(
      title: 'Sleep timer',
      children: [
        for (final m in minutes)
          ListTile(
            title: Text('$m minutes',
                style: const TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              _svc.startSleepTimer(Duration(minutes: m));
              Navigator.of(context).pop();
            },
          ),
        ListTile(
          title: const Text('Turn off',
              style: TextStyle(color: AppColors.textMuted)),
          onTap: () {
            _svc.cancelSleepTimer();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _share() {
    final t = _svc.currentTrack;
    if (t == null) return;
    final text = '${t.name} — ${t.artistName}'
        '${t.audioUrl.isNotEmpty ? '\n${t.audioUrl}' : ''}';
    // ignore: deprecated_member_use
    Share.share(text, subject: t.name);
  }

  void _sheet({required String title, required List<Widget> children}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...children,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Draggable multi-band graph: a connecting curve with a knob per band.
class _EqGraph extends StatelessWidget {
  final List<_BandVM> bands;
  final double min, max;
  final void Function(int index, double gain) onChanged;

  const _EqGraph({
    required this.bands,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  static const double _h = 150;
  static const double _pad = 16;

  double _gainToY(double gain) {
    final frac = (gain - min) / (max - min); // 0..1
    return (_h - _pad) - frac * (_h - 2 * _pad);
  }

  double _yToGain(double y) {
    final frac = ((_h - _pad) - y) / (_h - 2 * _pad);
    return min + frac.clamp(0.0, 1.0) * (max - min);
  }

  @override
  Widget build(BuildContext context) {
    final n = bands.length;
    return Column(
      children: [
        // Gain value labels.
        Row(
          children: [
            for (final b in bands)
              Expanded(
                child: Text(
                  b.gain.round().toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 9),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final colW = w / n;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _handle(d.localPosition, colW, n),
              onPanUpdate: (d) => _handle(d.localPosition, colW, n),
              child: CustomPaint(
                size: Size(w, _h),
                painter: _EqPainter(
                  gains: [for (final b in bands) _gainToY(b.gain)],
                  colW: colW,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        // Frequency labels.
        Row(
          children: [
            for (final b in bands)
              Expanded(
                child: Text(
                  _freq(b.centerHz),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 9),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _handle(Offset p, double colW, int n) {
    final i = (p.dx / colW).floor().clamp(0, n - 1);
    onChanged(i, _yToGain(p.dy));
  }

  String _freq(double hz) =>
      hz >= 1000 ? '${(hz / 1000).round()}K' : hz.round().toString();
}

class _EqPainter extends CustomPainter {
  final List<double> gains; // already mapped to Y
  final double colW;

  _EqPainter({required this.gains, required this.colW});

  @override
  void paint(Canvas canvas, Size size) {
    final n = gains.length;
    final pts = <Offset>[
      for (var i = 0; i < n; i++) Offset((i + 0.5) * colW, gains[i]),
    ];

    // Faint vertical guide lines.
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (final p in pts) {
      canvas.drawLine(Offset(p.dx, 8), Offset(p.dx, size.height - 8), guide);
    }

    // Smooth connecting curve through the knobs.
    final line = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < n - 1; i++) {
      final midX = (pts[i].dx + pts[i + 1].dx) / 2;
      path.cubicTo(midX, pts[i].dy, midX, pts[i + 1].dy,
          pts[i + 1].dx, pts[i + 1].dy);
    }
    canvas.drawPath(path, line);

    // Knobs.
    final knobFill = Paint()..color = AppColors.accent;
    final knobGlow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final p in pts) {
      canvas.drawCircle(p, 9, knobGlow);
      canvas.drawCircle(p, 6, knobFill);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_EqPainter old) =>
      old.gains != gains || old.colW != colW;
}
