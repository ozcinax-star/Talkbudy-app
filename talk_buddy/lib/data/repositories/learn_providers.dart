import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../curriculum/answer_evaluator.dart';
import '../curriculum/content_library.dart';
import '../curriculum/curriculum_models.dart';
import '../curriculum/dialogue_engine.dart';
import '../curriculum/progress_store.dart';
import '../services/profile_service.dart';
import 'providers.dart';

final profileServiceProvider = Provider<ProfileService>(
  (_) => throw UnimplementedError('main() içinde override edilir'),
);

final progressStoreProvider = Provider<ProgressStore>(
  (_) => throw UnimplementedError('main() içinde override edilir'),
);

class AccountController extends StateNotifier<AccountState> {
  final ProfileService _service;
  AccountController(this._service) : super(_service.load());

  Future<void> selectChild(String id) async {
    await _service.setActiveChild(id);
    state = state.copyWith(activeChildId: id);
  }

  void setRole(AccountRole role) => state = state.copyWith(activeRole: role);

  Future<void> upsertChild(ChildAccount child) async {
    final list = [...state.children];
    final i = list.indexWhere((c) => c.id == child.id);
    if (i >= 0) {
      list[i] = child;
    } else {
      list.add(child);
    }
    await _service.saveChildren(list);
    state = state.copyWith(children: list);
  }

  Future<void> removeChild(String id) async {
    final list = state.children.where((c) => c.id != id).toList();
    await _service.saveChildren(list);
    state = state.copyWith(children: list);
  }

  Future<void> setPin(AccountRole role, String pin) async {
    await _service.setPin(role, pin);
    state = state.copyWith(
      parentPinSet: role == AccountRole.parent ? true : state.parentPinSet,
      teacherPinSet: role == AccountRole.teacher ? true : state.teacherPinSet,
    );
  }

  Future<void> clearPin(AccountRole role) async {
    await _service.clearPin(role);
    state = state.copyWith(
      parentPinSet: role == AccountRole.parent ? false : state.parentPinSet,
      teacherPinSet: role == AccountRole.teacher ? false : state.teacherPinSet,
    );
  }

  bool verifyPin(AccountRole role, String pin) =>
      _service.verifyPin(role, pin);

  bool hasPin(AccountRole role) => _service.hasPin(role);
}

final accountProvider =
    StateNotifierProvider<AccountController, AccountState>(
  (ref) => AccountController(ref.watch(profileServiceProvider)),
);

final activeAccountProvider = Provider<ChildAccount>((ref) {
  final acc = ref.watch(accountProvider);
  final settings = ref.watch(settingsProvider);
  final child = acc.activeChild;
  if (child != null) return child;
  return ChildAccount(
    id: 'local',
    name: settings.childName,
    ageMonths: settings.childAgeMonths,
    avatar: settings.childAvatar,
    createdAt: DateTime.now(),
  );
});

class ProgressController extends StateNotifier<LearnerProgress> {
  final ProgressStore _store;
  final String profileId;

  ProgressController(this._store, this.profileId)
      : super(_store.load(profileId));

  Future<void> submit(LessonResult result) async {
    final next = _store.applyResult(state, result);
    state = next;
    await _store.save(profileId, next);
  }

  Future<void> reset() async {
    await _store.clear(profileId);
    state = const LearnerProgress();
  }
}

final progressProvider = StateNotifierProvider.family<ProgressController,
    LearnerProgress, String>(
  (ref, profileId) => ProgressController(
    ref.watch(progressStoreProvider),
    profileId,
  ),
);

final activeProgressProvider = Provider<LearnerProgress>((ref) {
  final child = ref.watch(activeAccountProvider);
  return ref.watch(progressProvider(child.id));
});

final unitsProvider = Provider<List<Unit>>((_) => ContentLibrary.units);

final nextLessonProvider = Provider<Lesson?>(
  (ref) => ref.watch(activeProgressProvider).nextLesson,
);

final dialogueEngineProvider =
    Provider.family<DialogueEngine, ({String lessonId, int seed})>((ref, arg) {
  final child = ref.watch(activeAccountProvider);
  final progress = ref.watch(activeProgressProvider);
  return DialogueEngine(
    ctx: GenerationContext(
      childName: child.name,
      ageMonths: child.ageMonths,
      mastery: progress.mastery,
      recentPrompts: progress.recentPrompts,
      recentWords: progress.recentWords,
      seed: arg.seed,
    ),
  );
});

final evaluatorProvider = Provider<AnswerEvaluator>((ref) {
  final child = ref.watch(activeAccountProvider);
  return AnswerEvaluator(ageMonths: child.ageMonths);
});

final classroomChildrenProvider =
    Provider.family<List<ChildAccount>, String>((ref, classroomId) {
  return ref.watch(accountProvider).childrenIn(classroomId);
});
