import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../state/subject_provider.dart';
import '../state/task_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_format.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const int _focusSeconds = 25 * 60;
  static const int _breakSeconds = 5 * 60;

  Timer? _ticker;
  int _secondsLeft = _focusSeconds;
  bool _running = false;
  bool _isBreak = false;
  int? _subjectId;
  int _completedSessions = 0;

  int get _total => _isBreak ? _breakSeconds : _focusSeconds;

  double get _progress => 1 - (_secondsLeft / _total);

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _complete();
        return;
      }
      setState(() => _secondsLeft = _secondsLeft - 1);
    });
  }

  Future<void> _complete() async {
    setState(() => _running = false);
    final TaskProvider tasks = context.read<TaskProvider>();
    if (!_isBreak) {
      await tasks.logSession(subjectId: _subjectId, seconds: _focusSeconds);
      if (!mounted) return;
      setState(() {
        _completedSessions = _completedSessions + 1;
        _isBreak = true;
        _secondsLeft = _breakSeconds;
      });
      _notify('Focus session saved. Take a 5 minute break.');
      return;
    }
    setState(() {
      _isBreak = false;
      _secondsLeft = _focusSeconds;
    });
    _notify('Break finished. Ready for another round?');
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _isBreak = false;
      _secondsLeft = _focusSeconds;
    });
  }

  void _notify(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final List<Subject> subjects = context.watch<SubjectProvider>().subjects;
    final TaskProvider tasks = context.watch<TaskProvider>();
    final Color accent = _isBreak ? AppColors.secondary : AppColors.primary;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
        children: <Widget>[
          const Text(
            'Study timer',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isBreak ? 'Break mode' : 'Focus mode · 25 minutes',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CustomPaint(
                    size: const Size(240, 240),
                    painter: _RingPainter(progress: _progress, color: accent),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        AppFormat.clock(_secondsLeft),
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _running ? 'Running' : 'Paused',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _running
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: _running ? 'Pause' : 'Start',
                  icon: _running ? Icons.pause : Icons.play_arrow,
                  onPressed: _toggle,
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Reset',
                variant: AppButtonVariant.outline,
                expand: false,
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Log this session to',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              GestureDetector(
                onTap: () => setState(() => _subjectId = null),
                child: _TimerChip(
                  label: 'General',
                  color: AppColors.textMuted,
                  selected: _subjectId == null,
                ),
              ),
              ...subjects.map(
                (Subject subject) => GestureDetector(
                  onTap: () => setState(() => _subjectId = subject.id),
                  child: _TimerChip(
                    label: subject.code,
                    color: hexColor(subject.color),
                    selected: _subjectId == subject.id,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _TimerStat(
                    label: 'Sessions today',
                    value: '$_completedSessions',
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: _TimerStat(
                    label: 'Study today',
                    value: AppFormat.duration(tasks.todaySeconds),
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: _TimerStat(
                    label: 'This week',
                    value: AppFormat.duration(tasks.weekSeconds),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({
    required this.label,
    required this.color,
    required this.selected,
  });

  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? color : AppColors.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerStat extends StatelessWidget {
  const _TimerStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - 18) / 2;
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = AppColors.border;
    final Paint fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.28318 * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
