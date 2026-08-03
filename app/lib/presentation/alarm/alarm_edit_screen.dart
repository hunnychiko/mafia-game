import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/alarm_model.dart';
import '../../services/alarm_service.dart';

class AlarmEditScreen extends ConsumerStatefulWidget {
  const AlarmEditScreen({super.key, this.alarm});

  /// Null when creating a new alarm.
  final AlarmModel? alarm;

  @override
  ConsumerState<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends ConsumerState<AlarmEditScreen> {
  late TimeOfDay _time;
  late Set<int> _repeatDays;
  late final TextEditingController _labelController;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    _time = alarm != null
        ? TimeOfDay(hour: alarm.hour, minute: alarm.minute)
        : TimeOfDay.now();
    _repeatDays = {...(alarm?.repeatDays ?? const <int>{})};
    _labelController = TextEditingController(text: alarm?.label ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.alarm != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '알람 수정' : '알람 추가'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _time.format(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('반복', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final weekday = i + 1; // DateTime.monday..sunday
              final isSelected = _repeatDays.contains(weekday);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _repeatDays.remove(weekday);
                  } else {
                    _repeatDays.add(weekday);
                  }
                }),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected
                      ? const Color(0xFF6B8CFF)
                      : const Color(0xFF1C2537),
                  child: Text(
                    _weekdayLabels[i],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          const Text('라벨', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _labelController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '예: 기상 알람',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1C2537),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white38, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이 알람은 영어 단어를 입력하고 뜻 문제를 맞혀야 꺼집니다. '
                    '최근 30일 안에 사용한 단어는 다시 사용할 수 없어요.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (isEditing) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                child: const Text('알람 삭제'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final service = await ref.read(alarmServiceProvider.future);
    final alarm = AlarmModel(
      id: widget.alarm?.id ?? AlarmService.generateId(),
      hour: _time.hour,
      minute: _time.minute,
      label: _labelController.text.trim(),
      repeatDays: _repeatDays,
      enabled: widget.alarm?.enabled ?? true,
    );
    await service.save(alarm);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final alarm = widget.alarm;
    if (alarm == null) return;
    final service = await ref.read(alarmServiceProvider.future);
    await service.delete(alarm.id);
    if (mounted) Navigator.pop(context);
  }
}
