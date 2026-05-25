from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import httpx
import os
import json
import asyncio
from dotenv import load_dotenv

load_dotenv()

# ── App init ─────────────────────────────────────────────────
app = FastAPI(
    title="Socio Backend",
    description="AI Co-Founder backend — Team Doppelganger",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── API Keys ──────────────────────────────────────────────────
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GROQ_API_KEY   = os.getenv("GROQ_API_KEY")
TAVILY_API_KEY = os.getenv("TAVILY_API_KEY")

# ── API URLs ──────────────────────────────────────────────────
GEMINI_URL = (
    "https://generativelanguage.googleapis.com"
    "/v1beta/models/gemini-2.0-flash:streamGenerateContent"
)
GROQ_URL   = "https://api.groq.com/openai/v1/chat/completions"
TAVILY_URL = "https://api.tavily.com/search"

# ── Prompt loader ─────────────────────────────────────────────
def load_prompt(filename: str) -> str:
    path = os.path.join("prompts", filename)
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        raise HTTPException(
            status_code=500,
            detail=f"Prompt file not found: {filename}"
        )

# ============================================================
# REQUEST MODELS
# ============================================================

class StartupContext(BaseModel):
    startup_name:  str = "My Startup"
    startup_idea:  str = ""
    startup_stage: str = "Idea stage"
    mrr:           str = "0"
    user_count:    str = "0"

class MessageItem(BaseModel):
    role:    str  # "user" or "socio"
    content: str

class ChatRequest(BaseModel):
    message:       str
    context:       StartupContext
    chat_history:  List[MessageItem] = []
    founder_name:  str = "Founder"

class OutreachRequest(BaseModel):
    target_name:    str
    target_company: str
    target_role:    str = "Investor"
    context:        StartupContext
    ask:            str = "a 15-minute intro call"
    traction:       str = ""

class InvestorFollowupRequest(BaseModel):
    investor_name:      str
    investor_firm:      str
    meeting_notes:      str = ""
    days_since_contact: int = 0
    status:             str = "follow-up"
    context:            StartupContext
    traction:           str = ""

class StressTestRequest(BaseModel):
    idea:    str
    context: StartupContext

# ============================================================
# CORE AI FUNCTIONS
# ============================================================

# ── Load + format system prompt ───────────────────────────────
def build_socio_system_prompt(
    context: StartupContext,
    chat_history: List[MessageItem],
    founder_name: str,
    persona_weights: dict = None
) -> str:

    history_text = ""
    for msg in chat_history[-10:]:  # last 10 messages only
        role = "Founder" if msg.role == "user" else "Socio"
        history_text += f"{role}: {msg.content}\n"

    weights_text = ""
    if persona_weights:
        weights_text = (
            f"\nCURRENT PERSONA BLEND (apply automatically):\n"
            f"Skeptic: {int(persona_weights.get('skeptic_weight', 0.33)*100)}% | "
            f"Hustler: {int(persona_weights.get('hustler_weight', 0.33)*100)}% | "
            f"Strategist: {int(persona_weights.get('strategist_weight', 0.34)*100)}%\n"
            f"Founder emotional state: {persona_weights.get('emotion', 'neutral')}\n"
            f"Founder intent: {persona_weights.get('intent', 'general')}\n"
        )

    template = load_prompt("socio_system_prompt.txt")

    return template.format(
        startup_name=context.startup_name,
        startup_idea=context.startup_idea or "Not described yet",
        startup_stage=context.startup_stage,
        mrr=context.mrr,
        user_count=context.user_count,
        last_updated="Today",
        chat_history=history_text or "No previous conversation.",
        founder_name=founder_name,
        persona_weights=weights_text
    )

# ── Mood classifier (fast Groq call) ─────────────────────────
async def classify_mood(
    message: str,
    recent_history: List[MessageItem]
) -> dict:

    history_text = " | ".join(
        [m.content for m in recent_history[-3:]]
    )

    template = load_prompt("mood_classifier_prompt.txt")
    prompt = template.format(
        message=message,
        recent_history=history_text
    )

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            res = await client.post(
                GROQ_URL,
                headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
                json={
                    "model": "llama-3.3-70b-versatile",
                    "messages": [{"role": "user", "content": prompt}],
                    "max_tokens": 250,
                    "temperature": 0.1
                }
            )
            text = res.json()["choices"][0]["message"]["content"]
            clean = text.strip().replace("```json", "").replace("```", "").strip()
            return json.loads(clean)
    except Exception as e:
        print(f"Mood classifier failed: {e}")
        # Safe defaults — never break the main chat flow
        return {
            "emotion": "neutral",
            "intent": "general",
            "urgency": "low",
            "mood_score": 0.7,
            "skeptic_weight": 0.33,
            "hustler_weight": 0.33,
            "strategist_weight": 0.34,
            "needs_sos": False,
            "reasoning": "classification unavailable"
        }

# ── Gemini streaming ──────────────────────────────────────────
async def stream_gemini(system_prompt: str, message: str):
    async with httpx.AsyncClient(timeout=30.0) as client:
        res = await client.post(
            f"{GEMINI_URL}?key={GEMINI_API_KEY}&alt=sse",
            json={
                "system_instruction": {
                    "parts": [{"text": system_prompt}]
                },
                "contents": [{
                    "role": "user",
                    "parts": [{"text": message}]
                }],
                "generationConfig": {
                    "maxOutputTokens": 450,
                    "temperature": 0.82
                }
            }
        )
        res.raise_for_status()
        async for line in res.aiter_lines():
            if line.startswith("data: "):
                try:
                    data = json.loads(line[6:])
                    chunk = (
                        data["candidates"][0]
                        ["content"]["parts"][0]["text"]
                    )
                    if chunk:
                        yield chunk
                except Exception:
                    continue

# ── Groq standard call (non-streaming) ───────────────────────
async def call_groq(
    system_prompt: str,
    user_message: str,
    max_tokens: int = 500,
    temperature: float = 0.8
) -> str:
    async with httpx.AsyncClient(timeout=20.0) as client:
        res = await client.post(
            GROQ_URL,
            headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
            json={
                "model": "llama-3.3-70b-versatile",
                "messages": [
                    {"role": "system",  "content": system_prompt},
                    {"role": "user",    "content": user_message}
                ],
                "max_tokens": max_tokens,
                "temperature": temperature
            }
        )
        res.raise_for_status()
        return res.json()["choices"][0]["message"]["content"]

# ── Tavily web research ───────────────────────────────────────
async def research_target(name: str, company: str) -> str:
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.post(
                TAVILY_URL,
                json={
                    "api_key": TAVILY_API_KEY,
                    "query": (
                        f"{name} {company} investor "
                        f"portfolio recent investments news 2025 2026"
                    ),
                    "max_results": 4,
                    "search_depth": "basic"
                }
            )
            results = res.json().get("results", [])
            snippets = [r.get("content", "")[:300] for r in results]
            return " | ".join(snippets)
    except Exception as e:
        print(f"Tavily search failed: {e}")
        return f"Research unavailable for {name} at {company}."

# ============================================================
# ENDPOINTS
# ============================================================

# ── /health — confirm backend is live ────────────────────────
@app.get("/health")
async def health():
    return {
        "status": "Socio backend is running",
        "team": "Doppelganger",
        "hackathon": "QuantCraft 2026"
    }

# ── /chat — main Socio AI conversation ───────────────────────
@app.post("/chat")
async def chat(request: ChatRequest):
    """
    Main chat endpoint.
    1. Runs mood classifier (Groq - fast)
    2. Builds Socio system prompt with persona weights
    3. Streams Gemini response token by token
    4. Falls back to Groq if Gemini fails
    """

    # Step 1: Classify mood (runs in parallel conceptually)
    mood = await classify_mood(request.message, request.chat_history)

    # Step 2: Build personalised system prompt
    system_prompt = build_socio_system_prompt(
        context=request.context,
        chat_history=request.chat_history,
        founder_name=request.founder_name,
        persona_weights=mood
    )

    # Step 3: Stream response
    async def generate():
        # First chunk — send mood data to Flutter
        yield f"data: {json.dumps({'type': 'mood', 'data': mood})}\n\n"

        full_response = ""
        gemini_failed = False

        # Try Gemini first (streaming)
        try:
            async for chunk in stream_gemini(system_prompt, request.message):
                full_response += chunk
                yield f"data: {json.dumps({'type': 'text', 'data': chunk})}\n\n"
        except Exception as e:
            print(f"Gemini failed: {e} — falling back to Groq")
            gemini_failed = True

        # Groq fallback (non-streaming, simulate word by word)
        if gemini_failed:
            try:
                response = await call_groq(system_prompt, request.message)
                for word in response.split(" "):
                    yield f"data: {json.dumps({'type': 'text', 'data': word + ' '})}\n\n"
                    await asyncio.sleep(0.02)  # slight delay = feels natural
            except Exception as e:
                yield f"data: {json.dumps({'type': 'error', 'data': 'Socio is temporarily unavailable. Try again.'})}\n\n"

        # Done signal
        yield f"data: {json.dumps({'type': 'done'})}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


# ── /outreach — cold email + call script + followups ─────────
@app.post("/outreach")
async def generate_outreach(request: OutreachRequest):
    """
    1. Tavily researches the target person
    2. Groq generates personalised email + call script + follow-ups
    3. Returns clean JSON
    """

    # Research the target
    research = await research_target(
        request.target_name,
        request.target_company
    )

    # Build prompt
    template = load_prompt("cold_email_prompt.txt")
    prompt = template.format(
        target_name=request.target_name,
        target_company=request.target_company,
        target_role=request.target_role,
        tavily_research=research,
        startup_name=request.context.startup_name,
        startup_idea=request.context.startup_idea,
        traction=request.traction or "Early stage, building product",
        ask=request.ask
    )

    try:
        result = await call_groq(
            system_prompt="You are an expert cold email writer. Return only valid raw JSON, no markdown, no preamble.",
            user_message=prompt,
            max_tokens=800,
            temperature=0.75
        )
        clean = result.strip().replace("```json", "").replace("```", "").strip()
        parsed = json.loads(clean)
        parsed["research_used"] = research[:200]  # include snippet for transparency
        return parsed
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="Failed to parse outreach response. Try again."
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── /investor-followup — personalised follow-up message ──────
@app.post("/investor-followup")
async def investor_followup(request: InvestorFollowupRequest):
    """
    Generates a specific follow-up message based on
    meeting notes and days since last contact.
    """

    template = load_prompt("investor_followup_prompt.txt")
    prompt = template.format(
        investor_name=request.investor_name,
        investor_firm=request.investor_firm,
        meeting_notes=request.meeting_notes or "No notes recorded",
        days_since_contact=request.days_since_contact,
        status=request.status,
        startup_name=request.context.startup_name,
        traction=request.traction or "Continuing to build"
    )

    try:
        result = await call_groq(
            system_prompt="You are Socio, an AI co-founder. Return only valid raw JSON.",
            user_message=prompt,
            max_tokens=400,
            temperature=0.7
        )
        clean = result.strip().replace("```json", "").replace("```", "").strip()
        return json.loads(clean)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── /stress-test — idea stress test with scorecard ───────────
@app.post("/stress-test")
async def stress_test(request: StressTestRequest):
    """
    Full idea stress test — assumption extraction,
    challenge questions, scorecard, verdict.
    """

    template = load_prompt("stress_test_prompt.txt")
    prompt = template.format(
        idea=request.idea,
        context=(
            f"Startup: {request.context.startup_name}. "
            f"Stage: {request.context.startup_stage}. "
            f"Idea: {request.context.startup_idea}"
        )
    )

    try:
        result = await call_groq(
            system_prompt=(
                "You are Socio in stress test mode. "
                "Be direct, honest, and structured."
            ),
            user_message=prompt,
            max_tokens=700,
            temperature=0.7
        )
        return {"analysis": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))