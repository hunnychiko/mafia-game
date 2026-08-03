import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/alarm_model.dart';
import '../../services/alarm_service.dart';
import 'alarm_edit_screen.dart';

class AlarmListScreen extends ConsumerWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(alarmServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('영어 단어 알람')),
      body: serviceAsync.when(
        data: (service) => _AlarmListBody(service: service),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
      floatingActionButton: serviceAsync.maybeWhen(
        data: (service) => FloatingActionButton(
          onPressed: () => _openEditor(context, ref),
          child: const Icon(Icons.add),
        ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlarmEditScreen()),
    );
    ref.invalidate(alarmServiceProvider);
  }
}

class _AlarmListBody extends StatelessWidget {
  const _AlarmListBody({required this.service});

  final AlarmService service;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final alarms = service.getAlarms();

    if (alarms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_off, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text('등록된 알람이 없습니다', style: TextStyle(color: Colors.white54)),
            SizedBox(height: 4),
            Text('+ 버튼을 눌러 알람을 추가하세요',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: alarms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _AlarmTile(
        alarm: alarms[index],
        service: service,
        weekdayLabels: _weekdayLabels,
      ),
    );
  }
}

class _AlarmTile extends ConsumerWidget {
  const _AlarmTile({
    required this.alarm,
    required this.service,
    required this.weekdayLabels,
  });

  final AlarmModel alarm;
  final AlarmService service;
  final List<String> weekdayLabels;

  String get _repeatLabel {
    if (alarm.repeatDays.isEmpty) return '한 번만';
    if (alarm.repeatDays.length == 7) return '매일';
    final sorted = alarm.repeatDays.toList()..sort();
    return sorted.map((d) => weekdayLabels[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          alarm.timeLabel,
          style: TextStyle(
            color: alarm.enabled ? Colors.white : Colors.white38,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          alarm.label.isNotEmpty ? '${alarm.label} · $_repeatLabel' : _repeatLabel,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        trailing: Switch(
          value: alarm.enabled,
          activeColor: const Color(0xFF6B8CFF),
          onChanged: (v) async {
            await service.setEnabled(alarm.id, v);
            ref.invalidate(alarmServiceProvider);
          },
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AlarmEditScreen(alarm: alarm)),
          );
          ref.invalidate(alarmServiceProvider);
        },
        onLongPress: () => _confirmDelete(context, ref),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('알람 삭제', style: TextStyle(color: Colors.white)),
        content: Text('${alarm.timeLabel} 알람을 삭제할까요?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await service.delete(alarm.id);
      ref.invalidate(alarmServiceProvider);
    }
  }
}
