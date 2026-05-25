# CLAUDE.md — Socio Project Master Guide
> This file is the primary developer manual for Socio. Keep it updated as features are built, refactored, or fixed.
> Last updated: May 26, 2026 | Version: 2.1 | Status: Emojis Removed + Android Physical Compilation & Runtime Fixes Complete + Pushed to GitHub ✅

---

## 🧠 What is Socio?

Socio is a high-fidelity mobile application (iOS + Android) that acts as a persistent, proactive **AI co-founder** for solo founders. Rather than a clinical utility tool, it is designed as an emotionally intelligent thinking partner. 

At its core is the **Adaptive Persona Engine**: a dynamic system that analyzes the founder's emotional tone and intent in real-time, automatically blending three primary advisory personas:
- **The Skeptic:** Plays devil's advocate, challenges assumptions, and points out risks.
- **The Hustler:** Focuses on immediate growth, sales, urgency, and speed to market.
- **The Strategist:** Looks at the big picture, long-term roadmaps, competitive moats, and unit economics.

**Core Vision:** "Every founder deserves a co-founder. Now they have one."

---

## 🏗 Project Structure

```
socio_ai/
├── CLAUDE.md                   ← Master developer guide (this file)
├── context.md                  ← Comprehensive product & development brain dump
├── socio_app/                  ← Flutter Frontend (Android + iOS)
│   ├── lib/
│   │   ├── main.dart           ← Firebase init, ProviderScope, root auth-gated navigation
│   │   ├── firebase_options.dart ← Auto-generated configuration for Firebase
│   │   ├── models/
│   │   │   ├── startup_model.dart  ← Startup configuration & serialization
│   │   │   ├── message_model.dart  ← Chat messages (role, content, stream states)
│   │   │   ├── investor_model.dart ← Investor pipeline details (stages, contacts) [UPDATED]
│   │   │   └── outreach_model.dart ← Outreach target, email copy, followups
│   │   ├── services/
│   │   │   ├── auth_service.dart   ← Auth handler (Google, Anonymous/Mock fallback) [UPDATED]
│   │   │   ├── firestore_service.dart ← Main Firestore database CRUD
│   │   │   ├── chat_service.dart   ← SSE connection & response processor
│   │   │   └── outreach_service.dart ← REST connector for cold email generator
│   │   ├── providers/
│   │   │   ├── auth_provider.dart  ← Auth riverpod providers & sign-in notifier
│   │   │   ├── startup_provider.dart ← Startup config provider & API sync
│   │   │   └── chat_provider.dart  ← Message lists, text-to-speech, recording states
│   │   ├── screens/
│   │   │   ├── sign_in_screen.dart ← Forest green themed login (Google + Offline mode)
│   │   │   ├── onboarding_screen.dart ← 3-step founder setup flow
│   │   │   ├── chat_screen.dart    ← Premium AI chat with SSE + persona weight visuals
│   │   │   ├── pipeline_screen.dart ← Drag-and-drop Kanban investor pipeline
│   │   │   ├── outreach_screen.dart ← AI cold email & outreach script writer
│   │   │   ├── mood_screen.dart    ← Founder wellness hub with line graphs & SOS mode
│   │   │   └── tracker_screen.dart  ← Standup metric tracking & goals
│   │   ├── widgets/
│   │   │   ├── chat_bubble.dart    ← Custom message bubbles
│   │   │   ├── investor_card.dart  ← Individual investor board tile
│   │   │   ├── mood_chart.dart     ← Muted weekly emotional trends line chart
│   │   │   └── jordan_insight_card.dart ← Custom cards for proactive prompts
│   │   └── navigation/
│   │       └── main_navigation.dart ← Custom bottom nav shell (Chat, Pipeline, Outreach, Tracker, Mood)
│   ├── pubspec.yaml            ← App dependencies (Riverpod, Dio, Hive, STT/TTS)
│   └── android/app/google-services.json
│
└── socio_backend/              ← FastAPI Backend (Python)
    ├── main.py                 ← Unified persona engine, stream logic, fallback cascade
    ├── requirements.txt        ← Backend package requirements
    ├── Procfile                ← Render deployment configuration
    ├── .env                    ← API Keys (Gemini, Groq, Tavily) — NOT COMMITTED
    └── prompts/                ← Prompt configurations with strict .format() variables
        ├── socio_system_prompt.txt
        ├── mood_classifier_prompt.txt
        ├── cold_email_prompt.txt
        ├── investor_followup_prompt.txt
        └── stress_test_prompt.txt
```

---

## 🛠 Tech Stack

### Frontend (Mobile App)
* **Framework:** Flutter (3.44.0) / Dart (3.x)
* **State Management:** Riverpod (`flutter_riverpod ^2.5.1`) — clean, reactive, and fully predictable.
* **Network Client:** Dio (`^5.7.0`) — handles connection, REST APIs, and Server-Sent Events (SSE) streaming.
* **Local Storage:** Hive (`^2.2.3`) — local offline persistence.
* **Voice Services:** `speech_to_text` (Voice input dictation) + `flutter_tts` (AI voice output).
* **Typography:** `google_fonts` (Inter + Outfit fonts).
* **Charts:** Muted custom Line Charts for mood trends.

### Backend (Server)
* **Framework:** FastAPI (Python) — extremely fast async request processing.
* **AI Model Waterfall (Cascade):**
  1. **Google Gemini 2.0 Flash (Primary):** High-speed streaming, massive 1M context window.
  2. **Groq (Llama 3.3 70B - Secondary Fallback):** Ultra-fast speed backup if Gemini rate-limits.
  3. **OpenRouter (Tertiary Fallback):** Ultimate backup.
* **Web Search Engine:** Tavily API (performs live startup target research).
* **Hosting:** Render (Free tier pre-configured).

### Database & Authentication (Firebase)
* **Firebase Auth:** Handles secure authentication (Google Sign-In + local Guest / Anonymous mode fallback).
* **Cloud Firestore:** Multi-tenant database storing real-time startup parameters, chat history, investors, and outreach campaigns. Features built-in offline caching and syncing.
* **Firebase Storage:** Planned document vault for deck storage.
* **FCM (Firebase Cloud Messaging):** Push notification system for daily schedules.

---

## 🎨 Design System & UI Aesthetics

Socio's visual identity draws heavy inspiration from **Pi AI (by Inflection)**. It avoids the cold, clinical feel of standard dashboards, using a warm, human, and modern aesthetic.

```
Forest Green Accent: #0B3A22  (Used for premium banners, splash logos, and headers)
Primary (Purple):    #6D28D9  (Brand primary, active states)
Light Purple BG:     #EDE9FE  (Subtle alerts, background tags)
Warm Cream BG:       #F7F4EB  (Primary background for screens and scaffolds)
Text Primary:        #0F172A  (Deep slate for high readability)
Text Muted:          #64748B  (Sage-tinged slate for labels)
Border Color:        #E2E8F0  (Soft divider color)
```

### Premium UI Enhancements Built:
1. **Interactive Glassmorphic Tabs:** Beautiful floating indicators inside screens.
2. **Fluid Drag-and-Drop Kanban Board:** The Investor Pipeline allows dragging cards between 9 statuses with smooth haptic feedback and animations.
3. **Interactive Persona Gauge:** Located at the top of the chat screen, it visualizes the blended persona mix (e.g., Skeptic: 60%, Hustler: 25%, Strategist: 15%) as a colorful, dynamic status bar.
4. **Soft Mood Line-Chart:** The wellness screen features a smooth, customized line graph reflecting daily mood scores over the past 7 days.

---

## 🔌 API Endpoints (Fully Built & Tested ✅)

### 1. `POST /chat`
Streams real-time messages using Server-Sent Events (SSE). 
* **Process:** Classifies emotional tone + intent (Groq, <200ms) → computes persona weights → injects weights into `socio_system_prompt.txt` → streams Gemini response.
* **Stream Structure:**
  - Chunk 1: `{type: "mood", data: {score: 0.8, emotion: "excited"}}` (used by Flutter to update live UI)
  - Sub-chunks: `{type: "text", data: "..."}` (tokens streamed to chat box)
  - Chunk End: `{type: "done"}`

### 2. `POST /outreach`
Researches target companies and leads live via Tavily, then generates a complete outreach campaign including:
* A highly personalized cold email copy
* An interactive cold calling script
* A 3-step follow-up timeline

### 3. `POST /investor-followup`
Accepts meeting details, investor parameters, and time elapsed to generate a personalized follow-up email draft.

### 4. `POST /stress-test`
Generates a structured, intense critical stress test of the startup's core business model, exposing hidden risks and vulnerabilities.

### 5. `GET /health`
Validates backend system integrity and API key configurations.

---

## 🏗 Firestore Database Schema

```
users/ {uid}
  ├── name: String
  ├── email: String
  ├── created_at: Timestamp
  │
  └── startups/ {startup_id}
        ├── name: String
        ├── idea: String
        ├── stage: String (e.g., "Seed", "Idea Stage")
        ├── mrr: String
        ├── user_count: String
        ├── updated_at: Timestamp
        │
        ├── messages/ {message_id}
        │     ├── role: String ("user" | "socio")
        │     ├── content: String
        │     ├── mood_score: Double
        │     └── timestamp: Timestamp
        │
        ├── investors/ {investor_id}
        │     ├── name: String
        │     ├── firm: String
        │     ├── status: String (InvestorStatus Enum)
        │     ├── notes: String
        │     ├── warmthScore: Integer
        │     ├── lastContactDate: String (ISO)
        │     ├── nextFollowUpDate: String (ISO)
        │     └── followUpsSent: Array<String>
        │
        ├── outreach/ {outreach_id}
        │     ├── target_name: String
        │     ├── target_company: String
        │     ├── email_body: String
        │     ├── call_script: String
        │     ├── followups: Array<Map>
        │     └── created_at: Timestamp
        │
        └── mood_logs/ {log_id}
              ├── score: Double
              ├── emotion: String
              └── timestamp: Timestamp
```

---

## 🧩 Feature Status & Implementation Details

| Feature | Status | Screen | Component / Backend |
|---|---|---|---|
| **Google Sign-In** | ⚠️ Offline Fallback | `sign_in_screen.dart` | Wired in `AuthService`. Live auth works, fallback to `MockUser` (Offline Mode) activates seamlessly if Firebase is blocked or unconfigured. |
| **Startup Onboarding** | ✅ Complete | `onboarding_screen.dart` | Captures core startup profile and MRR, setting up the foundation in Firestore. |
| **Adaptive Persona Chat**| ✅ Complete | `chat_screen.dart` | Displays live blended persona metrics. Connects to `/chat` SSE stream. |
| **Voice Command (STT)** | ✅ Complete | `chat_screen.dart` | Tapping the mic button records voice input using `speech_to_text`. |
| **Voice Output (TTS)** | ✅ Complete | `chat_screen.dart` | Plays back AI responses via `flutter_tts` speaker toggle. |
| **Activity Tracker** | ✅ Complete | `tracker_screen.dart` | Manages founder priority metrics, todo list items, and scheduled meetings. |
| **Cold Outreach Suite** | ✅ Complete | `outreach_screen.dart` | Fetches Tavily company research and generates cold email/script copy from `/outreach`. |
| **Investor Pipeline** | ✅ Complete | `pipeline_screen.dart` | High-fidelity Kanban board supporting full drag-and-drop statuses and follow-up email drafts. |
| **Mood Tracker & Graph**| ✅ Complete | `mood_screen.dart` | Plots weekly mood scores using custom line charts and features a quick mood-log card. |
| **Founder SOS** | ✅ Complete | `mood_screen.dart` | Triggers custom coping suggestions, critical priority focusing, and offline coping mechanisms if emotional scores drop. |
| **Startup Stress Test** | ✅ Complete | `chat_screen.dart` | Triggers a live `/stress-test` endpoint call from the chat options menu. |
| **Daily FCM standups** | 🔲 Backlog | Server + FCM | Triggers a 9:00 AM push notification asking for daily tasks. |
| **Document Vault** | 🔲 Backlog | future tab | Firebase Storage uploads for pitch decks and legal files. |

---

## 🛠 Critical Code Fixes (May 2026)

Recently resolved key compile-time blocker errors and runtime platform compatibility issues to bring the app into a fully stable, multi-platform operational state:

### 1. AuthService `isMockMode` Integration
* **Problem:** `FirestoreService` queried `_authService.isMockMode` to decide whether to write to the mock in-memory database or real Firestore. However, `isMockMode` was not defined on `AuthService`.
* **Fix:** Added a secure getter in [auth_service.dart](file:///c:/socio-ai/socio_app/lib/services/auth_service.dart) returning `true` when the `currentUser` is a local `MockUser`:
  ```dart
  bool get isMockMode => currentUser is MockUser;
  ```

### 2. InvestorModel `copyWith` Named Parameters
* **Problem:** In the mock pipeline, `addInvestor` attempted to assign a mock ID using `investor.copyWith(id: '...')`. However, `copyWith` did not accept `id` (it was hardcoded to `id: id` inside the signature).
* **Fix:** Modified `copyWith` in [investor_model.dart](file:///c:/socio-ai/socio_app/lib/models/investor_model.dart) to accept optional `id` and `createdAt` parameters.

### 3. Absolute Emoji Removal & Spacing Refinements
* **Problem:** The user requested to remove all graphical emojis across the entire project for a clean, premium visual aesthetic.
* **Fix:** Conducted a comprehensive recursive codebase sweep. Removed emojis from all views, snackbars, and models:
  * **`investor_model.dart`**: Removed `✅` comment and modified the `emoji` getter to return clean empty strings `""` for all pipeline statuses.
  * **`chat_screen.dart`**: Replaced face emojis (`😊`, `😐`, `😔`) inside `_moodEmoji` with semantic strings (`'Happy'`, `'Neutral'`, `'Sad'`). Removed star symbols `✦` from snackbars.
  * **`onboarding_screen.dart` & `pipeline_screen.dart`**: Removed sparkle emojis (`✨`), checkmarks (`✓`), and swept all layout cards to remove the custom rendering widgets and paddings where stashed emojis were previously displayed, ensuring pixel-perfect layout alignment.

### 4. Physical Android Device & SDK Support Fixes
* **Problem:** Compiling the app for a physical device running modern Android (Android 15) failed with a chain of dependency and package classpath crashes.
* **Fixes Implemented:**
  * **Java 8 Desugaring**: Configured [android/app/build.gradle.kts](file:///c:/socio-ai/socio_app/android/app/build.gradle.kts) to enable `isCoreLibraryDesugaringEnabled = true` and added the `com.android.tools:desugar_jdk_libs:2.0.4` dependency block, allowing `flutter_local_notifications` Java 8 features to build successfully on Android.
  * **MainActivity ClassPath Renaming**: Resolved a package namespace mismatch. The `google-services.json` setup required `com.doppelganger.socio`, but the `MainActivity.kt` source was mislocated under `com/example/socio_app`. Created the new file in the correct package directory `src/main/kotlin/com/doppelganger/socio/MainActivity.kt` and updated the `package` declaration to completely fix the Dalvik startup `ClassNotFoundException`.
  * **Notification Schedule Mode Crash**: Changed local standup notifications in [standup_service.dart](file:///c:/socio-ai/socio_app/lib/services/standup_service.dart) to use `AndroidScheduleMode.inexactAllowWhileIdle` instead of `exactAllowWhileIdle`, preventing immediate startup `SecurityException` crashes on Android 12+ devices.
  * **Startup Firebase Safe-Bypass**: Wrapped `Firebase.initializeApp` in a `try-catch` block inside [main.dart](file:///c:/socio-ai/socio_app/lib/main.dart) to prevent local network timeouts with mock keys from blocking `runApp()`, completely eliminating black screen freezes.
  * **Dynamic ADB Reverse Port Forwarding**: Switched `_kBaseUrl` to `'http://localhost:8000'` in both `chat_service.dart` and `competitor_radar_screen.dart`. When bridged with `adb reverse tcp:8000 tcp:8000`, this enables physical Android phones to communicate perfectly with your computer's local FastAPI backend!

### 5. Chat History Async welcome message Spam Prevention
* **Problem:** Riverpod's `setStartupContext` was running asynchronously on build cycles, creating a race condition where multiple streams noticed an empty chat history simultaneously, causing the app to append and save multiple duplicate welcome messages to Firestore.
* **Fix:** Implemented an initialization gate lock `_hasInitialized` inside `ChatNotifier` in [chat_provider.dart](file:///c:/socio-ai/socio_app/lib/providers/chat_provider.dart) to securely block duplicate welcome executions.

*All fixes are verified, compilation is completely clean, and the updated code compiles with 0 errors on Chrome and physical Android devices.*

---

## 🚀 Execution & Verification Checklist

To spin up and run the project:

### 1. Running the Backend
Ensure you are in the `socio_backend` folder, set up your keys, and launch:
```powershell
cd socio_backend
# Add keys to .env: GEMINI_API_KEY, GROQ_API_KEY, TAVILY_API_KEY
pip install -r requirements.txt
uvicorn main:app --reload
```

### 2. Launching the App
Run Flutter from the `socio_app` directory:
```powershell
cd socio_app
flutter pub get
flutter run
```
* **Verify Login:** Click **"Try Offline Mode"** on the SignIn screen to instantly access the app with the mock DB, or configure Google credentials in Firebase Console for production sync.
* **Verify Chat:** Ask a question, toggle the Speaker icon for voice synthesis, or use the mic button for voice dictation.
* **Verify Pipeline:** Drag cards between the stages, and check details to write a draft follow-up email.
* **Verify Outreach:** Type in a company (e.g., "Google") and role (e.g., "PM"), click "Research & Write", and watch it pull live company analysis and drafts.
