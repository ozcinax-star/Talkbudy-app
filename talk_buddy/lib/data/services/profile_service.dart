import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccountRole { child, parent, teacher }

extension AccountRoleX on AccountRole {
  String get label => switch (this) {
        AccountRole.child => 'Çocuk',
        AccountRole.parent => 'Veli',
        AccountRole.teacher => 'Öğretmen',
      };

  String get emoji => switch (this) {
        AccountRole.child => '🧸',
        AccountRole.parent => '👨‍👩‍👧',
        AccountRole.teacher => '🎓',
      };

  bool get needsPin => this != AccountRole.child;

  static AccountRole parse(String? v) => AccountRole.values.firstWhere(
        (r) => r.name == v,
        orElse: () => AccountRole.child,
      );
}

@immutable
class ChildAccount {
  final String id;
  final String name;
  final int ageMonths;
  final String avatar;
  final DateTime createdAt;
  final String? classroomId;
  final String? note;

  const ChildAccount({
    required this.id,
    required this.name,
    required this.ageMonths,
    required this.avatar,
    required this.createdAt,
    this.classroomId,
    this.note,
  });

  String get ageLabel {
    final y = ageMonths ~/ 12;
    final m = ageMonths % 12;
    if (y == 0) return '$m aylık';
    if (m == 0) return '$y yaş';
    return '$y yaş $m ay';
  }

  ChildAccount copyWith({
    String? name,
    int? ageMonths,
    String? avatar,
    String? classroomId,
    String? note,
  }) =>
      ChildAccount(
        id: id,
        name: name ?? this.name,
        ageMonths: ageMonths ?? this.ageMonths,
        avatar: avatar ?? this.avatar,
        createdAt: createdAt,
        classroomId: classroomId ?? this.classroomId,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ageMonths': ageMonths,
        'avatar': avatar,
        'createdAt': createdAt.toIso8601String(),
        'classroomId': classroomId,
        'note': note,
      };

  factory ChildAccount.fromJson(Map<String, dynamic> j) => ChildAccount(
        id: j['id'] as String,
        name: j['name'] as String,
        ageMonths: j['ageMonths'] as int,
        avatar: j['avatar'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        classroomId: j['classroomId'] as String?,
        note: j['note'] as String?,
      );
}

@immutable
class Classroom {
  final String id;
  final String name;
  final String teacherName;

  const Classroom({
    required this.id,
    required this.name,
    required this.teacherName,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'teacherName': teacherName};

  factory Classroom.fromJson(Map<String, dynamic> j) => Classroom(
        id: j['id'] as String,
        name: j['name'] as String,
        teacherName: j['teacherName'] as String,
      );
}

@immutable
class AccountState {
  final List<ChildAccount> children;
  final List<Classroom> classrooms;
  final String? activeChildId;
  final AccountRole activeRole;
  final bool parentPinSet;
  final bool teacherPinSet;

  const AccountState({
    this.children = const [],
    this.classrooms = const [],
    this.activeChildId,
    this.activeRole = AccountRole.child,
    this.parentPinSet = false,
    this.teacherPinSet = false,
  });

  ChildAccount? get activeChild {
    if (children.isEmpty) return null;
    for (final c in children) {
      if (c.id == activeChildId) return c;
    }
    return children.first;
  }

  List<ChildAccount> childrenIn(String classroomId) =>
      children.where((c) => c.classroomId == classroomId).toList();

  AccountState copyWith({
    List<ChildAccount>? children,
    List<Classroom>? classrooms,
    String? activeChildId,
    AccountRole? activeRole,
    bool? parentPinSet,
    bool? teacherPinSet,
  }) =>
      AccountState(
        children: children ?? this.children,
        classrooms: classrooms ?? this.classrooms,
        activeChildId: activeChildId ?? this.activeChildId,
        activeRole: activeRole ?? this.activeRole,
        parentPinSet: parentPinSet ?? this.parentPinSet,
        teacherPinSet: teacherPinSet ?? this.teacherPinSet,
      );
}

class ProfileService {
  static const _kChildren = 'acc_children';
  static const _kClassrooms = 'acc_classrooms';
  static const _kActiveChild = 'acc_active_child';
  static const _kParentPin = 'acc_parent_pin';
  static const _kTeacherPin = 'acc_teacher_pin';
  static const _kSalt = 'acc_salt';

  final SharedPreferences _prefs;
  ProfileService(this._prefs);

  static Future<ProfileService> create() async =>
      ProfileService(await SharedPreferences.getInstance());

  String get _salt {
    var s = _prefs.getString(_kSalt);
    if (s == null || s.isEmpty) {
      s = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      _prefs.setString(_kSalt, s);
    }
    return s;
  }

  String _hash(String pin) =>
      sha256.convert(utf8.encode('$_salt::$pin')).toString();

  AccountState load() {
    final children = _decodeList(_kChildren)
        .map(ChildAccount.fromJson)
        .toList();
    final classrooms = _decodeList(_kClassrooms)
        .map(Classroom.fromJson)
        .toList();

    return AccountState(
      children: children.isEmpty ? _seedChildren() : children,
      classrooms: classrooms.isEmpty ? _seedClassrooms() : classrooms,
      activeChildId: _prefs.getString(_kActiveChild),
      parentPinSet: (_prefs.getString(_kParentPin) ?? '').isNotEmpty,
      teacherPinSet: (_prefs.getString(_kTeacherPin) ?? '').isNotEmpty,
    );
  }

  List<Map<String, dynamic>> _decodeList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveChildren(List<ChildAccount> children) => _prefs.setString(
        _kChildren,
        jsonEncode(children.map((c) => c.toJson()).toList()),
      );

  Future<void> saveClassrooms(List<Classroom> rooms) => _prefs.setString(
        _kClassrooms,
        jsonEncode(rooms.map((c) => c.toJson()).toList()),
      );

  Future<void> setActiveChild(String id) =>
      _prefs.setString(_kActiveChild, id);

  Future<void> setPin(AccountRole role, String pin) {
    final key = role == AccountRole.teacher ? _kTeacherPin : _kParentPin;
    return _prefs.setString(key, _hash(pin));
  }

  bool verifyPin(AccountRole role, String pin) {
    final key = role == AccountRole.teacher ? _kTeacherPin : _kParentPin;
    final stored = _prefs.getString(key);
    if (stored == null || stored.isEmpty) return true;
    return stored == _hash(pin);
  }

  bool hasPin(AccountRole role) {
    final key = role == AccountRole.teacher ? _kTeacherPin : _kParentPin;
    return (_prefs.getString(key) ?? '').isNotEmpty;
  }

  Future<void> clearPin(AccountRole role) {
    final key = role == AccountRole.teacher ? _kTeacherPin : _kParentPin;
    return _prefs.remove(key);
  }

  Future<void> reset() async {
    await Future.wait([
      _prefs.remove(_kChildren),
      _prefs.remove(_kClassrooms),
      _prefs.remove(_kActiveChild),
      _prefs.remove(_kParentPin),
      _prefs.remove(_kTeacherPin),
    ]);
  }

  static List<ChildAccount> _seedChildren() => [
        ChildAccount(
          id: 'c1',
          name: 'Elif',
          ageMonths: 52,
          avatar: '🐰',
          createdAt: DateTime(2026, 4, 12),
          classroomId: 'k1',
        ),
        ChildAccount(
          id: 'c2',
          name: 'Kerem',
          ageMonths: 41,
          avatar: '🦊',
          createdAt: DateTime(2026, 5, 3),
          classroomId: 'k1',
        ),
        ChildAccount(
          id: 'c3',
          name: 'Deniz',
          ageMonths: 67,
          avatar: '🐢',
          createdAt: DateTime(2026, 3, 21),
          classroomId: 'k1',
        ),
        ChildAccount(
          id: 'c4',
          name: 'Zeynep',
          ageMonths: 35,
          avatar: '🐥',
          createdAt: DateTime(2026, 6, 9),
          classroomId: 'k2',
        ),
        ChildAccount(
          id: 'c5',
          name: 'Mert',
          ageMonths: 58,
          avatar: '🦕',
          createdAt: DateTime(2026, 2, 14),
          classroomId: 'k2',
        ),
      ];

  static List<Classroom> _seedClassrooms() => const [
        Classroom(id: 'k1', name: 'Papatya Sınıfı', teacherName: 'Aynur Yörük'),
        Classroom(id: 'k2', name: 'Menekşe Sınıfı', teacherName: 'Aynur Yörük'),
      ];
}
