# context.md — Socio Project Full Context
> Everything decided, everything discussed, everything reasoned. This is the brain dump of the entire project so far.
> Last updated: May 2026

---

## 📖 How This Project Started

Deepak Pandey (Team Doppelganger) participated in QuantCraft Hackathon at Galgotias University. Out of 250 participants he was shortlisted into the top 50 for the offline 24-hour final round. The project went through several iterations before landing on Socio:

**Ideas considered and rejected:**
- AI legal document simplifier
- Plant disease detector
- AI mock interviewer
- On-chain academic credential verifier
- Competitor intelligence engine
- API changelog explainer
- Natural language BI tool
- AI RFP generator

**Why Socio won:**
It combines B2C targeting with a genuine unsolved problem (solo founder isolation), maps perfectly to the AI/ML track, has a clear monetisation story, and is highly demonstrable in a live pitch setting. The adaptive persona engine is a technically interesting differentiator that separates it from "just another ChatGPT wrapper."

---

## 🎯 Core Insight Behind the Product

The insight that drives everything: solo founders don't fail because they're not smart or hardworking. They fail because they make critical decisions alone. The problem isn't productivity — it's isolation. Every tool in the market (Notion, Linear, Slack, ChatGPT) solves the productivity problem. Nobody is solving the thinking partner problem.

Socio is not a productivity tool. It's a thinking partner. That distinction drives every product decision.

---

## 🧠 The Adaptive Persona Engine — Why It Works This Way

Early version: three separate persona modes (Skeptic, Hustler, Strategist) that the founder manually selects from a menu.

**Why we changed it:** Cognitive overhead. When you're stressed at 2am you don't want to think about which mode to activate. Real co-founders don't announce their approach — they just naturally adapt. Making it automatic is what separates Socio from a feature and makes it a product.

**How the engine works:**
1. Every message the founder sends goes to FastAPI
2. A fast Groq call (under 200ms) classifies emotional tone + intent
3. Returns persona weights (e.g. 60% Skeptic, 30% Hustler, 10% Strategist)
4. These weights are injected into the Jordan/Socio unified system prompt
5. Gemini responds with the blended personality
6. The founder never sees any of this — they just feel the right energy

**The unified prompt approach:** Instead of three separate system prompts, one master prompt defines all three personas and instructs the model to blend them dynamically. This gives better results because the model has full context when deciding how to respond, rather than a cold classifier making a separate judgment.

---

## 📱 Why Mobile-First (Not Web App)

This was a deliberate product decision, not a technical one. Founders don't sit at laptops all day — they're in meetings, commuting, pitching, at coffee shops. A web app that requires you to open a browser and re-explain your context is useless in that lifestyle.

The mobile-first decision enables:
- Push notifications (9am standup is impossible on web)
- Voice input during commutes
- Always-available in your pocket
- Feels like a person, not a tool

This is also a strong pitch angle: "ChatGPT is a tool you open. Socio is a partner that lives in your pocket."

---

## 📲 Why Flutter (Not React Native or Native)

**vs React Native:**
- Flutter compiles to native ARM — no JavaScript bridge
- Better performance for real-time streaming chat
- Pixel-perfect identical UI on Android and iOS
- Hot reload is faster

**vs Native Kotlin + Swift:**
- One codebase = both platforms
- Solo developer can't maintain two codebases in 24 hours
- Flutter has enough packages for everything needed

**vs PWA:**
- Can't do real push notifications
- Can't access native STT/TTS properly
- Doesn't feel like a real app to judges

---

## 💰 Why Free Stack (And Which APIs)

The hackathon rule doesn't require a paid stack. The free tier strategy:

**Gemini 2.5 Flash (Google AI Studio):**
- 1,500 requests/day free, no credit card
- 1M token context window — perfect for long startup memory
- Best free LLM quality available in 2026
- This is the primary LLM

**Groq (Llama 3.3 70B):**
- 14,400 requests/day free
- 315 tokens/second — near-instant responses
- Used as fallback when Gemini hits rate limit
- Also used for mood classifier (fast, cheap)

**OpenRouter:**
- 20+ free models
- Tertiary fallback
- Also useful for persona variety experiments

**Why not Claude API:**
- Requires credit card — no genuine free tier
- Post-hackathon when monetised, switch to Claude for better reasoning

**Why not OpenAI:**
- Also requires credit card for API access

**Total monthly cost: $0.00**

---

## 🔥 Firestore — Why This Database

**Alternatives considered:**
- Supabase: also good but slightly more setup
- SQLite local only: no cross-device sync
- MongoDB Atlas: free tier but more complex

**Firestore wins because:**
- Real-time sync across devices out of the box
- Works offline (caches locally, syncs when reconnected)
- Firebase ecosystem — Auth + FCM + Storage all in one
- Flutter has excellent Firebase packages
- Free Spark plan is more than enough for hackathon + first 500 users
- The startup context needs to sync so Jordan always has it regardless of device

---

## 🎨 UI Design Decisions

**Reference:** Pi AI app (Mobbin) — the first emotionally intelligent AI app. Warm, minimal, human. This is the aesthetic Socio should match.

**Why this aesthetic:**
- Most AI tools look clinical and cold (ChatGPT, Claude)
- Socio is positioned as a human-like partner — the UI should feel that way
- Warm off-white background (#F8F7FF) instead of pure white
- Purple as primary — feels premium without being cold
- Large readable text, generous whitespace
- Chat bubbles that feel like iMessage not a corporate dashboard

**Navigation decision:** Bottom nav bar with 5 tabs (not a drawer, not top tabs). Bottom nav is the natural pattern for mobile apps that users check frequently. Socio should feel like WhatsApp or Instagram — something you open multiple times a day.

---

## 💡 The Daily Standup Notification — Why It's The Most Important Feature

Every other feature in Socio requires the founder to open the app. The daily standup notification is the only feature where Socio comes to the founder.

9am notification: "Good morning. What are your 3 priorities today?"
9pm check-in: "What got blocked today?"

This is what makes Socio feel like a real co-founder rather than a productivity app. Real co-founders don't wait to be consulted — they check in. This single feature drives daily retention better than any other feature in the app.

Build this even if it means cutting something else.

---

## 🎤 Presentation Strategy

**The hook:** Opens with a question to the audience ("How many of you have had to make a really hard decision alone?") instead of the standard "Hi I'm [name] presenting [project]." This immediately makes the pitch personal and memorable.

**The naming strategy:** Call the AI "Socio" not "our AI" or "the system." Every time. This makes the product feel real and alive. Judges will leave saying "that app with Socio" not "that AI founder app."

**The closing:** "Every founder deserves a co-founder. Now they have one." Said slowly. Then silence. No trailing off. This is the strongest possible ending and should never be followed with anything.

**Demo flow:**
1. Onboard live on stage (30 seconds)
2. Chat with Socio — show adaptive response (45 seconds)
3. Generate cold email live (30 seconds)
4. Show pipeline briefly (15 seconds)
5. Close with the line

**The Doppelganger angle:** Team name connects to product concept. "We called ourselves Doppelganger because that's what Socio is — your double, always thinking alongside you."

---

## ❓ Expected Judge Questions & Positioning

**"How is this different from ChatGPT?"**
Five angles: memory, proactive behaviour, context across features, persona adaptation, mobile-first. Lead with memory — it's the most visceral difference.

**"What's your moat?"**
Data network effect. The more a founder uses Socio, the more it knows about their startup. Switching cost grows every week. That's a real moat.

**"Why would someone pay Rs.1,599?"**
Advisor charges Rs.5,000-20,000 per hour. Socio is Rs.1,599 per month for 24/7 access that knows your startup. The ROI is obvious.

**"How are you implementing the persona engine?"**
Unified system prompt with three built-in personas. Fast Groq mood classifier runs before every Gemini call, returns weights, weights are injected into the prompt. No separate models, no manual switching. Under 200ms overhead.

**"Why Flutter?"**
Cross-platform (iOS + Android), single codebase, solo developer, hot reload, near-native performance, Material 3 built in.

---

## 🛠 Tools & Responsibilities

| Tool | What it does |
|---|---|
| Claude (claude.ai) | Backend code, prompts, debugging, architecture |
| Bolt.new | Full screen UI generation from description |
| v0.dev | Specific polished UI components |
| Cursor | Primary code editor — all actual development |
| TRAE AI | Mandatory hackathon requirement — screenshots |
| Firebase Console | Database management, auth monitoring |
| Postman | API endpoint testing before Flutter integration |
| Mobbin | UI design reference (Pi AI app) |
| Render | FastAPI backend hosting (free) |

---

## 📊 Business Model

**Free tier:**
- 20 AI interactions per day
- Basic Socio chat
- 1 active investor in pipeline
- Limited outreach (3 per month)

**Pro — Rs.1,599/month (~$19):**
- Unlimited everything
- Voice mode
- Investor simulator
- Competitor radar
- Document vault
- Priority response speed

**Enterprise:**
- White-label for accelerators and incubators
- Their cohort founders get Socio branded as the accelerator's tool
- Per-seat or flat monthly pricing

**Target:** 1,000 Pro users in 6 months = Rs.1.6 Cr MRR
**Market:** 50M solo founders globally, $15B startup tools market

---

## 🔮 Future Scope (Post-Hackathon)

In priority order:

1. **Voice-first mode** — full hands-free conversation, not just mic button
2. **Smart calendar integration** — auto-detect meetings, pre-brief Socio
3. **Metrics anomaly detection** — AI spots revenue drops proactively
4. **Competitor radar v2** — weekly auto-refresh with push alerts
5. **Founder SOS v2** — anonymous founder support network connection
6. **Team mode** — multiple co-founders, shared Socio context
7. **App Store + Play Store** — public release
8. **Enterprise white-label** — accelerator partnerships
9. **Fine-tuned Socio** — trained on successful founder conversations
10. **Smart target finding** — Socio suggests who to cold email, not just writes the email

---

## 📝 Decisions Log

| Decision | What | Why |
|---|---|---|
| May 20 2026 | Named app "Socio" | From Italian "socio" = business partner. Sounds cool, international, one word |
| May 20 2026 | Named AI "Socio AI" | Consistent with app name, personal |
| May 20 2026 | Flutter over React Native | iOS + Android, solo dev, hackathon speed |
| May 20 2026 | Gemini as primary LLM | Best free tier available, 1M context |
| May 20 2026 | Unified prompt over separate prompts | Better blending, one API call |
| May 20 2026 | Automatic persona vs manual | Removes cognitive overhead, feels like real co-founder |
| May 20 2026 | Mobile-first over web | Push notifications, commute use, founder lifestyle |
| May 20 2026 | Warm minimal UI (Pi AI ref) | Differentiate from clinical AI tools |
| May 20 2026 | FastAPI on Render | Free, Python, easy to deploy |
| May 20 2026 | Firestore over Supabase | Firebase ecosystem consolidation |

---

## ⚠️ Known Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Gemini rate limit during demo | Groq fallback wired in, seamless switch |
| Venue WiFi failure | Hotspot ready, backend pre-deployed |
| App crash during demo | Backup screen recording prepared |
| Running out of time | Strict priority order, cut mood/SOS if needed |
| TRAE proof missing | Screenshot schedule built into timeline |
| APK not installing | Test release build night before |
| Voice not working on stage | Mic button already tested, can demo text only |

---

## 🔄 Update Log

| Date | Update |
|---|---|
| May 2026 | Initial file created — pre-hackathon |
| — | Add updates here as features are built |

---

*Keep this file updated throughout the hackathon. After building each feature, add an entry to the Update Log and mark the feature status in CLAUDE.md.*
