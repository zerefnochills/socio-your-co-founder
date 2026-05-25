import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OutreachService — calls FastAPI /outreach
// Backend: Tavily researches target → Gemini generates cold email,
//          call script, and Day 1/3/7 follow-up sequence
// ─────────────────────────────────────────────────────────────────────────────

// ── Config ────────────────────────────────────────────────────────────────────
final String _kBaseUrl = kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000'; // Dynamic localhost for Web / Android emulator


// ── Data models ───────────────────────────────────────────────────────────────

class OutreachRequest {
  final String targetName;
  final String targetCompany;
  final String targetRole;
  final String startupName;
  final String startupIdea;
  final String traction; // e.g. "500 waitlist users, 3 pilot customers"
  final String ask;      // e.g. "15-minute intro call"

  const OutreachRequest({
    required this.targetName,
    required this.targetCompany,
    required this.targetRole,
    required this.startupName,
    required this.startupIdea,
    this.traction = 'Early stage, building MVP',
    this.ask = '15-minute intro call',
  });

  Map<String, dynamic> toJson() => {
        'target_name': targetName,
        'target_company': targetCompany,
        'target_role': targetRole,
        'startup_name': startupName,
        'startup_idea': startupIdea,
        'traction': traction,
        'ask': ask,
      };
}

class FollowUp {
  final int day;
  final String subject;
  final String body;

  const FollowUp({
    required this.day,
    required this.subject,
    required this.body,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) => FollowUp(
        day: (json['day'] as num?)?.toInt() ?? 1,
        subject: json['subject'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );
}

class OutreachResult {
  final String coldEmailSubject;
  final String coldEmailBody;
  final String callScript;
  final List<FollowUp> followUps;
  final String tavilyInsight; // key insight from research

  const OutreachResult({
    required this.coldEmailSubject,
    required this.coldEmailBody,
    required this.callScript,
    required this.followUps,
    this.tavilyInsight = '',
  });

  factory OutreachResult.fromJson(Map<String, dynamic> json) => OutreachResult(
        coldEmailSubject: json['cold_email_subject'] as String? ?? '',
        coldEmailBody: json['cold_email_body'] as String? ?? '',
        callScript: json['call_script'] as String? ?? '',
        tavilyInsight: json['tavily_insight'] as String? ?? '',
        followUps: ((json['follow_ups'] as List<dynamic>?) ?? [])
            .map((e) => FollowUp.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class OutreachService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 45), // Tavily can be slow
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<OutreachResult> generate(OutreachRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/outreach',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) throw Exception('Empty response from backend');
      return OutreachResult.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
            'Request timed out. Tavily research takes ~10s — try again.');
      case DioExceptionType.connectionError:
        return Exception('Cannot reach Socio backend. Is it running?');
      default:
        final status = e.response?.statusCode;
        return Exception('Backend error ($status). Check your API keys.');
    }
  }
}
