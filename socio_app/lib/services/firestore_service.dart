import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/startup_model.dart';
import '../models/message_model.dart';
import '../models/investor_model.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  bool get _isMock => _authService.isMockMode;

  // ── Mock In-Memory Databases ──────────────────────────────────
  static StartupModel? _mockStartup;
  static final _startupController = StreamController<StartupModel?>.broadcast();

  static final List<MessageModel> _mockMessages = [];
  static final _messagesController = StreamController<List<MessageModel>>.broadcast();

  static final List<Map<String, dynamic>> _mockMoodLogs = [];

  static final List<InvestorModel> _mockInvestors = [];
  static final _investorsController = StreamController<List<InvestorModel>>.broadcast();

  static final List<Map<String, dynamic>> _mockOutreach = [];
  static final _outreachController = StreamController<List<Map<String, dynamic>>>.broadcast();

  // ── Helpers ───────────────────────────────────────────────────

  String get _uid {
    try {
      return _auth.currentUser?.uid ?? 'guest_user';
    } catch (_) {
      return 'guest_user';
    }
  }

  DocumentReference get _userRef => _db.collection('users').doc(_uid);

  CollectionReference get _startupsRef =>
      _userRef.collection('startups');

  // ── USER ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUser() async {
    if (_isMock) {
      return {
        'name': 'Guest Founder',
        'email': 'guest@socio.ai',
        'photo_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=120',
        'created_at': DateTime.now(),
      };
    }
    final doc = await _userRef.get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  // ── STARTUP ───────────────────────────────────────────────────

  /// Get the primary startup. Creates a default one if none exists.
  Future<StartupModel> getOrCreateStartup() async {
    if (_isMock) {
      _mockStartup ??= StartupModel(
        id: 'mock-startup-id',
        name: '',
        idea: '',
        stage: 'Idea stage',
        mrr: '0',
        userCount: '0',
        customPersona: '',
        updatedAt: DateTime.now(),
      );
      return _mockStartup!;
    }
    final snapshot = await _startupsRef.limit(1).get();

    if (snapshot.docs.isEmpty) {
      // First time — create a blank startup doc
      final ref = _startupsRef.doc();
      final blank = StartupModel(
        id: ref.id,
        name: '',
        idea: '',
        stage: 'Idea stage',
        mrr: '0',
        userCount: '0',
        customPersona: '',
        updatedAt: DateTime.now(),
      );
      await ref.set(blank.toFirestore());
      return blank.copyWith(id: ref.id);
    }

    return StartupModel.fromFirestore(snapshot.docs.first);
  }

  /// Save/update startup context — called from onboarding + settings
  Future<StartupModel> saveStartup(StartupModel startup) async {
    if (_isMock) {
      _mockStartup = startup.copyWith(
        id: startup.id.isEmpty ? 'mock-startup-id' : startup.id,
      );
      _startupController.add(_mockStartup);
      return _mockStartup!;
    }
    if (startup.id.isEmpty) {
      // New startup
      final ref = _startupsRef.doc();
      await ref.set(startup.toFirestore());
      return startup.copyWith(id: ref.id);
    } else {
      // Update existing
      await _startupsRef.doc(startup.id).update(startup.toFirestore());
      return startup;
    }
  }

  /// Stream of the primary startup — live updates from Firestore
  Stream<StartupModel?> watchStartup(String startupId) {
    if (_isMock) {
      final controller = StreamController<StartupModel?>.broadcast();
      scheduleMicrotask(() {
        controller.add(_mockStartup);
      });
      final sub = _startupController.stream.listen((val) {
        controller.add(val);
      });
      controller.onCancel = () {
        sub.cancel();
      };
      return controller.stream;
    }
    return _startupsRef.doc(startupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StartupModel.fromFirestore(doc);
    });
  }

  // ── MESSAGES ──────────────────────────────────────────────────

  CollectionReference _messagesRef(String startupId) =>
      _startupsRef.doc(startupId).collection('messages');

  /// Save a single message to Firestore
  Future<void> saveMessage(String startupId, MessageModel message) async {
    if (_isMock) {
      _mockMessages.add(message);
      _messagesController.add(List.from(_mockMessages));
      return;
    }
    await _messagesRef(startupId).add(message.toFirestore());
  }

  /// Get the last N messages for the chat screen
  Future<List<MessageModel>> getRecentMessages(
    String startupId, {
    int limit = 30,
  }) async {
    if (_isMock) {
      if (_mockMessages.isEmpty) {
        _mockMessages.add(MessageModel(
          id: 'mock-welcome-msg',
          role: MessageRole.socio,
          content: "Hey! I'm Socio, your AI co-founder. Ready to scale your startup? Let's talk strategy, user growth, or outreach!",
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ));
      }
      return _mockMessages.take(limit).toList();
    }
    final snapshot = await _messagesRef(startupId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList()
        .reversed
        .toList(); // Reverse so oldest is first
  }

  /// Stream of messages — real-time for the chat screen
  Stream<List<MessageModel>> watchMessages(String startupId) {
    if (_isMock) {
      if (_mockMessages.isEmpty) {
        _mockMessages.add(MessageModel(
          id: 'mock-welcome-msg',
          role: MessageRole.socio,
          content: "Hey! I'm Socio, your AI co-founder. Ready to scale your startup? Let's talk strategy, user growth, or outreach!",
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ));
      }
      final controller = StreamController<List<MessageModel>>.broadcast();
      scheduleMicrotask(() {
        controller.add(List.from(_mockMessages));
      });
      final sub = _messagesController.stream.listen((val) {
        controller.add(val);
      });
      controller.onCancel = () {
        sub.cancel();
      };
      return controller.stream;
    }
    return _messagesRef(startupId)
        .orderBy('timestamp', descending: false)
        .limitToLast(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // ── MOOD LOGS ─────────────────────────────────────────────────

  CollectionReference _moodRef(String startupId) =>
      _startupsRef.doc(startupId).collection('mood_logs');

  /// Save a mood entry — called after each Socio response
  Future<void> saveMoodLog(
    String startupId, {
    required double score,
    required String emotion,
  }) async {
    if (_isMock) {
      _mockMoodLogs.add({
        'score': score,
        'emotion': emotion,
        'timestamp': DateTime.now(),
      });
      return;
    }
    await _moodRef(startupId).add({
      'score': score,
      'emotion': emotion,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get mood logs for the last 7 days
  Future<List<Map<String, dynamic>>> getMoodLogs(
    String startupId, {
    int days = 7,
  }) async {
    if (_isMock) {
      return _mockMoodLogs;
    }
    final since = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _moodRef(startupId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  /// Average mood score for the last 7 days (0.0 to 1.0)
  Future<double> getWeeklyMoodScore(String startupId) async {
    if (_isMock) {
      if (_mockMoodLogs.isEmpty) return 0.7;
      final total = _mockMoodLogs.fold(0.0, (acc, log) => acc + (log['score'] ?? 0.7));
      return total / _mockMoodLogs.length;
    }
    final logs = await getMoodLogs(startupId, days: 7);
    if (logs.isEmpty) return 0.7;
    final total = logs.fold(0.0, (acc, log) => acc + (log['score'] ?? 0.7));
    return total / logs.length;
  }

  // ── INVESTORS ─────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _pipelineInvestorsRef(
          String uid, String startupId) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('startups')
          .doc(startupId)
          .collection('investors');

  Stream<List<InvestorModel>> investorsStream(String uid, String startupId) {
    if (_isMock) {
      if (_mockInvestors.isEmpty) {
        _mockInvestors.addAll([
          InvestorModel(
            id: 'inv-1',
            name: 'Naval Ravikant',
            firm: 'AngelList / AirChat',
            status: InvestorStatus.contacted,
            notes: 'Met at tech meetup. Interested in AI + social.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            lastContactDate: DateTime.now().subtract(const Duration(days: 2)),
            nextFollowUpDate: DateTime.now().add(const Duration(days: 3)),
          ),
          InvestorModel(
            id: 'inv-2',
            name: 'Marc Andreessen',
            firm: 'a16z',
            status: InvestorStatus.meeting,
            notes: 'Intrigued by our custom persona engine.',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            lastContactDate: DateTime.now().subtract(const Duration(days: 1)),
            nextFollowUpDate: DateTime.now().add(const Duration(days: 4)),
          ),
        ]);
      }
      final controller = StreamController<List<InvestorModel>>.broadcast();
      scheduleMicrotask(() {
        controller.add(List.from(_mockInvestors));
      });
      final sub = _investorsController.stream.listen((val) {
        controller.add(val);
      });
      controller.onCancel = () {
        sub.cancel();
      };
      return controller.stream;
    }
    return _pipelineInvestorsRef(uid, startupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InvestorModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<String> addInvestor(
      String uid, String startupId, InvestorModel investor) async {
    if (_isMock) {
      final newInv = investor.copyWith(
        id: 'investor-${DateTime.now().millisecondsSinceEpoch}',
      );
      _mockInvestors.add(newInv);
      _investorsController.add(List.from(_mockInvestors));
      return newInv.id;
    }
    final ref = _pipelineInvestorsRef(uid, startupId).doc();
    await ref.set(investor.toFirestore());
    return ref.id;
  }

  Future<void> updateInvestor(
      String uid, String startupId, InvestorModel investor) async {
    if (_isMock) {
      final idx = _mockInvestors.indexWhere((inv) => inv.id == investor.id);
      if (idx != -1) {
        _mockInvestors[idx] = investor;
        _investorsController.add(List.from(_mockInvestors));
      }
      return;
    }
    await _pipelineInvestorsRef(uid, startupId).doc(investor.id).update(investor.toFirestore());
  }

  Future<void> updateInvestorStatus(String uid, String startupId,
      String investorId, InvestorStatus newStatus) async {
    if (_isMock) {
      final idx = _mockInvestors.indexWhere((inv) => inv.id == investorId);
      if (idx != -1) {
        _mockInvestors[idx] = _mockInvestors[idx].copyWith(status: newStatus);
        _investorsController.add(List.from(_mockInvestors));
      }
      return;
    }
    await _pipelineInvestorsRef(uid, startupId)
        .doc(investorId)
        .update({'status': newStatus.name});
  }

  Future<void> recordContact(
      String uid, String startupId, String investorId) async {
    if (_isMock) {
      final idx = _mockInvestors.indexWhere((inv) => inv.id == investorId);
      if (idx != -1) {
        final now = DateTime.now();
        _mockInvestors[idx] = _mockInvestors[idx].copyWith(
          lastContactDate: now,
          nextFollowUpDate: now.add(const Duration(days: 5)),
        );
        _investorsController.add(List.from(_mockInvestors));
      }
      return;
    }
    final now = DateTime.now();
    await _pipelineInvestorsRef(uid, startupId).doc(investorId).update({
      'lastContactDate': now.toIso8601String(),
      'nextFollowUpDate':
          now.add(const Duration(days: 5)).toIso8601String(),
      'followUpsSent': FieldValue.arrayUnion([now.toIso8601String()]),
    });
  }

  Future<void> deleteInvestor(
      String uid, String startupId, String investorId) async {
    if (_isMock) {
      _mockInvestors.removeWhere((inv) => inv.id == investorId);
      _investorsController.add(List.from(_mockInvestors));
      return;
    }
    await _pipelineInvestorsRef(uid, startupId).doc(investorId).delete();
  }

  // ── OUTREACH ──────────────────────────────────────────────────

  CollectionReference _outreachRef(String startupId) =>
      _startupsRef.doc(startupId).collection('outreach');

  Future<void> saveOutreach(
    String startupId,
    Map<String, dynamic> outreach,
  ) async {
    if (_isMock) {
      _mockOutreach.add({
        'id': 'outreach-${DateTime.now().millisecondsSinceEpoch}',
        ...outreach,
        'created_at': DateTime.now(),
      });
      _outreachController.add(List.from(_mockOutreach));
      return;
    }
    await _outreachRef(startupId).add({
      ...outreach,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchOutreach(String startupId) {
    if (_isMock) {
      final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
      scheduleMicrotask(() {
        controller.add(List.from(_mockOutreach));
      });
      final sub = _outreachController.stream.listen((val) {
        controller.add(val);
      });
      controller.onCancel = () {
        sub.cancel();
      };
      return controller.stream;
    }
    return _outreachRef(startupId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }
}
