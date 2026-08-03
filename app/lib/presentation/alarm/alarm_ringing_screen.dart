import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/word_repository.dart';
import '../../services/alarm_service.dart';
import '../../services/word_history_service.dart';

enum _Stage { enterWord, quiz, solved }

/// Full-screen alarm dismissal flow: the user must type a fresh English word
/// (one not used to dismiss an alarm in the last 30 days) and then answer a
/// multiple-choice question about that word's meaning before the alarm stops.
class AlarmRingingScreen extends ConsumerStatefulWidget {
  const AlarmRingingScreen({super.key, required this.alarmId, this.alarmLabel});

  final int alarmId;
  final String? alarmLabel;

  @override
  ConsumerState<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends ConsumerState<AlarmRingingScreen> {
  final _wordController = TextEditingController();
  _Stage _stage = _Stage.enterWord;
  String? _wordError;
  String? _quizError;
  WordQuiz? _quiz;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordRepoAsync = ref.watch(wordRepositoryProvider);
    final historyAsync = ref.watch(wordHistoryServiceProvider);
    final alarmServiceAsync = ref.watch(alarmServiceProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: SafeArea(
          child: wordRepoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('오류: $e', style: const TextStyle(color: Colors.white70)),
            ),
            data: (wordRepo) => historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('오류: $e', style: const TextStyle(color: Colors.white70)),
              ),
              data: (history) => alarmServiceAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('오류: $e', style: const TextStyle(color: Colors.white70)),
                ),
                data: (alarmService) => _buildBody(wordRepo, history, alarmService),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    WordRepository wordRepo,
    WordHistoryService history,
    AlarmService alarmService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.alarmLabel != null && widget.alarmLabel!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.alarmLabel!,
                style: const TextStyle(color: Colors.white54, fontSize: 16)),
          ],
          const Spacer(),
          Expanded(
            flex: 3,
            child: switch (_stage) {
              _Stage.enterWord => _WordEntry(
                  controller: _wordController,
                  errorText: _wordError,
                  onSubmit: () => _onWordSubmitted(wordRepo, history),
                ),
              _Stage.quiz => _QuizView(
                  quiz: _quiz!,
                  errorText: _quizError,
                  onChoiceSelected: (choice) =>
                      _onChoiceSelected(choice, history, alarmService),
                ),
              _Stage.solved => const _SolvedView(),
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void _onWordSubmitted(WordRepository wordRepo, WordHistoryService history) {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      setState(() => _wordError = '영어 단어를 입력해주세요');
      return;
    }
    if (!wordRepo.isEnglishWord(word)) {
      setState(() => _wordError = '영어 단어만 입력할 수 있어요');
      return;
    }
    final entry = wordRepo.lookup(word);
    if (entry == null) {
      setState(() => _wordError = '사전에 없는 단어예요. 다른 단어를 입력해보세요');
      return;
    }
    if (history.isDuplicate(word)) {
      setState(() => _wordError = '최근 30일 안에 이미 사용한 단어예요. 다른 단어를 입력해주세요');
      return;
    }

    setState(() {
      _wordError = null;
      _quiz = wordRepo.buildQuiz(entry);
      _stage = _Stage.quiz;
    });
  }

  Future<void> _onChoiceSelected(
    String choice,
    WordHistoryService history,
    AlarmService alarmService,
  ) async {
    if (choice != _quiz!.correctMeaning) {
      setState(() => _quizError = '틀렸어요! 다시 시도해보세요');
      return;
    }

    await history.recordUsage(_quiz!.word);
    await alarmService.handleSolved(widget.alarmId);

    if (!mounted) return;
    setState(() {
      _quizError = null;
      _stage = _Stage.solved;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.of(context).pop();
  }
}

class _WordEntry extends StatelessWidget {
  const _WordEntry({
    required this.controller,
    required this.errorText,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.alarm, color: Color(0xFF6B8CFF), size: 40),
        const SizedBox(height: 16),
        const Text(
          '영어 단어를 입력하세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '아무 영어 단어나 좋아요. 단, 최근 30일 안에 쓴 단어는 안 돼요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          style: const TextStyle(color: Colors.white, fontSize: 22),
          decoration: InputDecoration(
            hintText: 'apple',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF111827),
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class _SolvedView extends StatelessWidget {
  const _SolvedView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: Colors.greenAccent, size: 56),
        SizedBox(height: 16),
        Text(
          '정답입니다! 알람을 끕니다',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView({
    required this.quiz,
    required this.errorText,
    required this.onChoiceSelected,
  });

  final WordQuiz quiz;
  final String? errorText;
  final ValueChanged<String> onChoiceSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          quiz.word,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '이 단어의 뜻은 무엇일까요?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 12),
          Text(errorText!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
        ],
        const SizedBox(height: 24),
        ...quiz.choices.map(
          (choice) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: () => onChoiceSelected(choice),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF1C2537)),
                backgroundColor: const Color(0xFF111827),
              ),
              child: Text(choice, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
