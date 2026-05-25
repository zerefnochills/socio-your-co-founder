import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/startup_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Helpers ───────────────────────────────────────────────────

  String get _uid => _auth.currentUser!.uid;

  DocumentReference get _userRef => _db.collection('users').doc(_uid);

  CollectionReference get _startupsRef =>
      _userRef.collection('startups');

  // ── USER ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUser() async {
    final doc = await _userRef.get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  // ── STARTUP ───────────────────────────────────────────────────

  /// Get the primary startup. Creates a default one if none exists.
  Future<StartupModel> getOrCreateStartup() async {
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
        updatedAt: DateTime.now(),
      );
      await ref.set(blank.toFirestore());
      return blank.copyWith(id: ref.id);
    }

    return StartupModel.fromFirestore(snapshot.docs.first);
  }

  /// Save/update startup context — called from onboarding + settings
  Future<StartupModel> saveStartup(StartupModel startup) async {
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
    await _messagesRef(startupId).add(message.toFirestore());
  }

  /// Get the last N messages for the chat screen
  Future<List<MessageModel>> getRecentMessages(
    String startupId, {
    int limit = 30,
  }) async {
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
    final logs = await getMoodLogs(startupId, days: 7);
    if (logs.isEmpty) return 0.7;
    final total = logs.fold(0.0, (sum, log) => sum + (log['score'] ?? 0.7));
    return total / logs.length;
  }

  // ── INVESTORS ─────────────────────────────────────────────────

  CollectionReference _investorsRef(String startupId) =>
      _startupsRef.doc(startupId).collection('investors');

  Future<void> addInvestor(
    String startupId,
    Map<String, dynamic> investor,
  ) async {
    await _investorsRef(startupId).add({
      ...investor,
      'created_at': FieldValue.serverTimestamp(),
      'last_contact': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateInvestorStatus(
    String startupId,
    String investorId,
    String status,
  ) async {
    await _investorsRef(startupId).doc(investorId).update({
      'status': status,
      'last_contact': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchInvestors(String startupId) {
    return _investorsRef(startupId)
        .orderBy('last_contact', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }

  // ── OUTREACH ──────────────────────────────────────────────────

  CollectionReference _outreachRef(String startupId) =>
      _startupsRef.doc(startupId).collection('outreach');

  Future<void> saveOutreach(
    String startupId,
    Map<String, dynamic> outreach,
  ) async {
    await _outreachRef(startupId).add({
      ...outreach,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchOutreach(String startupId) {
    return _outreachRef(startupId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }
}
