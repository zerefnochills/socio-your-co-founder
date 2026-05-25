from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, model_validator
from typing import Optional, List
import httpx
import os
import json
import asyncio
import re
import google.generativeai as genai
from groq import Groq
from tavily import TavilyClient
from dotenv import load_dotenv

# ── Robust Path Resolution ─────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
dotenv_path = os.path.join(BASE_DIR, ".env")
load_dotenv(dotenv_path)

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

# ── API Clients ────────────────────────────────────────────────
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
groq_client = Groq(api_key=GROQ_API_KEY) if GROQ_API_KEY else None
tavily_client = TavilyClient(api_key=TAVILY_API_KEY) if TAVILY_API_KEY else None

# ── API URLs ──────────────────────────────────────────────────
GEMINI_URL = (
    "https://generativelanguage.googleapis.com"
    "/v1beta/models/gemini-2.0-flash:streamGenerateContent"
)
GROQ_URL   = "https://api.groq.com/openai/v1/chat/completions"
TAVILY_URL = "https://api.tavily.com/search"

# ── Prompt loader ─────────────────────────────────────────────
def load_prompt(filename: str) -> str:
    path = os.path.join(BASE_DIR, "prompts", filename)
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        raise HTTPException(
            status_code=500,
            detail=f"Prompt file not found: {filename}"
        )

# ── JSON Extraction Helper ────────────────────────────────────
def extract_json(text: str) -> dict:
    """
    Robustly extracts and parses a JSON object from text.
    Handles potential markdown fencing (e.g. ```json ... ```) or conversational preambles.
    """
    text = text.strip()
    
    # 1. Try finding boundaries
    start = text.find('{')
    end = text.rfind('}')
    
    if start != -1 and end != -1 and end > start:
        json_str = text[start:end+1]
        try:
            return json.loads(json_str)
        except json.JSONDecodeError:
            pass
            
    # 2. Try removing backticks manually
    clean = text.replace("```json", "").replace("```", "").strip()
    try:
        return json.loads(clean)
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON. Raw text was:\n{text}")
        raise e

# ============================================================
# REQUEST MODELS
# ============================================================

class StartupContext(BaseModel):
    startup_name:  str = "My Startup"
    startup_idea:  str = ""
    startup_stage: str = "Idea stage"
    mrr:           str = "0"
    user_count:    str = "0"
    customPersona: Optional[str] = ""

class MessageItem(BaseModel):
    role:    str  # "user" or "socio"
    content: str

class ChatRequest(BaseModel):
    message:       str
    context:       Optional[StartupContext] = None
    chat_history:  List[MessageItem] = []
    founder_name:  str = "Founder"

    @model_validator(mode="before")
    @classmethod
    def normalize_keys(cls, data):
        if not isinstance(data, dict):
            return data
        
        # 1. Normalize history vs chat_history
        if "history" in data and not data.get("chat_history"):
            data["chat_history"] = data.pop("history")
            
        # 2. Normalize context nested vs flat
        if "context" not in data or data["context"] is None:
            ctx = {}
            for k in ["startup_name", "startup_idea", "startup_stage", "mrr", "user_count", "customPersona"]:
                if k in data:
                    ctx[k] = data.get(k)
            data["context"] = ctx
            
        return data

class OutreachRequest(BaseModel):
    target_name:    str
    target_company: str
    target_role:    str = "Investor"
    context:        Optional[StartupContext] = None
    ask:            str = "a 15-minute intro call"
    traction:       str = ""

    @model_validator(mode="before")
    @classmethod
    def normalize_keys(cls, data):
        if not isinstance(data, dict):
            return data
        
        if "context" not in data or data["context"] is None:
            ctx = {}
            for k in ["startup_name", "startup_idea", "startup_stage", "mrr", "user_count", "customPersona"]:
                if k in data:
                    ctx[k] = data.get(k)
            data["context"] = ctx
            
        return data

class InvestorFollowupRequest(BaseModel):
    investor_name:      str
    investor_firm:      str
    meeting_notes:      str = ""
    days_since_contact: int = 0
    status:             str = "follow-up"
    context:            Optional[StartupContext] = None
    traction:           str = ""

    @model_validator(mode="before")
    @classmethod
    def normalize_keys(cls, data):
        if not isinstance(data, dict):
            return data
        
        if "context" not in data or data["context"] is None:
            ctx = {}
            for k in ["startup_name", "startup_idea", "startup_stage", "mrr", "user_count", "customPersona"]:
                if k in data:
                    ctx[k] = data.get(k)
            data["context"] = ctx
            
        return data

class StressTestRequest(BaseModel):
    idea:    str
    context: Optional[StartupContext] = None

    @model_validator(mode="before")
    @classmethod
    def normalize_keys(cls, data):
        if not isinstance(data, dict):
            return data
        
        if "context" not in data or data["context"] is None:
            ctx = {}
            for k in ["startup_name", "startup_idea", "startup_stage", "mrr", "user_count", "customPersona"]:
                if k in data:
                    ctx[k] = data.get(k)
            data["context"] = ctx
            
        return data

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

    prompt = template.format(
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

    if context.customPersona:
        prompt += (
            f"\n\n---"
            f"\n\n## CUSTOM CO-FOUNDER PERSONA INSTRUCTIONS\n\n"
            f"The founder has set a custom style, focus, and background for you. Always integrate this into your persona:\n"
            f"{context.customPersona}\n"
        )

    return prompt

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
            return extract_json(text)
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
        "keys_configured": {
            "gemini": bool(GEMINI_API_KEY),
            "groq": bool(GROQ_API_KEY),
            "tavily": bool(TAVILY_API_KEY)
        },
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
        # Align mood payload with the nested structure expected by the Flutter frontend (MoodData.fromJson)
        formatted_mood = {
            "emotion": mood.get("emotion", "neutral"),
            "score": mood.get("mood_score", mood.get("score", 0.7)),
            "needs_sos": mood.get("needs_sos", False),
            "persona_weights": {
                "skeptic": mood.get("skeptic_weight", mood.get("skeptic", 0.33)),
                "hustler": mood.get("hustler_weight", mood.get("hustler", 0.33)),
                "strategist": mood.get("strategist_weight", mood.get("strategist", 0.34))
            },
            # Keep flat keys for compatibility with backend or other versions
            "mood_score": mood.get("mood_score", 0.7),
            "skeptic_weight": mood.get("skeptic_weight", 0.33),
            "hustler_weight": mood.get("hustler_weight", 0.33),
            "strategist_weight": mood.get("strategist_weight", 0.34),
            "urgency": mood.get("urgency", "low"),
            "intent": mood.get("intent", "general"),
            "reasoning": mood.get("reasoning", "")
        }

        # First chunk — send formatted mood data to Flutter
        yield f"data: {json.dumps({'type': 'mood', 'data': formatted_mood})}\n\n"

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
        parsed = extract_json(result)
        parsed["research_used"] = research[:200]  # include snippet for transparency
        return parsed
    except Exception as e:
        print(f"Outreach generation failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate outreach: {str(e)}"
        )


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
        return extract_json(result)
    except Exception as e:
        print(f"Investor follow-up failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate follow-up: {str(e)}"
        )


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


class LeadFinderRequest(BaseModel):
    startup_name: str
    startup_idea: str
    startup_stage: str
    target_customer: str          # e.g. "B2B SaaS companies scaling their sales team"
    num_search_rounds: int = 3    # how many Tavily queries to run (more = richer results)

class InvestorFinderRequest(BaseModel):
    startup_name: str
    startup_idea: str
    startup_stage: str            # "Idea Stage" | "Pre-seed" | "Seed" | "Series A"
    mrr: str
    user_count: str
    geography: str = "India"      # focus region

class InvestorEnrichRequest(BaseModel):
    investor_name: str
    firm: str
    startup_name: str
    startup_idea: str


# ════════════════════════════════════════════════════════════════════════════
# HELPER — shared JSON extractor (strip markdown fences from LLM output)
# ════════════════════════════════════════════════════════════════════════════

def _extract_json(text: str) -> list:
    """Strip markdown fences and parse JSON array from LLM response."""
    cleaned = re.sub(r"```(?:json)?", "", text).strip().rstrip("`").strip()
    # Find the outermost [...] array
    start = cleaned.find("[")
    end   = cleaned.rfind("]") + 1
    if start == -1 or end == 0:
        raise ValueError(f"No JSON array found in LLM output: {cleaned[:200]}")
    return json.loads(cleaned[start:end])


# ════════════════════════════════════════════════════════════════════════════
# ENDPOINT 1: POST /find-leads
# Auto-discovers real B2B leads using Tavily + Gemini
# ════════════════════════════════════════════════════════════════════════════

@app.post("/find-leads")
async def find_leads(req: LeadFinderRequest):
    """
    Runs multiple targeted Tavily searches based on startup context,
    feeds results to Gemini, returns a structured list of prioritised leads.
    """
    # ── Step 1: Build search queries tailored to this founder ──────────────
    search_queries = [
        f"{req.target_customer} companies hiring 2026",
        f"{req.target_customer} startups recently funded seed series A 2025 2026",
        f"best {req.target_customer} tools software companies India 2026",
        f"{req.startup_idea} potential customers use cases companies",
        f"companies struggling with {req.startup_idea.lower()} problems 2026",
    ]
    # Only run num_search_rounds queries (caller controls depth vs speed)
    search_queries = search_queries[:req.num_search_rounds]

    # ── Step 2: Run Tavily searches in parallel ────────────────────────────
    async def perform_search(query):
        try:
            res = await asyncio.to_thread(
                tavily_client.search,
                query=query,
                search_depth="advanced",
                max_results=6,
                include_answer=True,
            )
            return res
        except Exception as e:
            print(f"Tavily search failed for '{query}': {e}")
            return None

    search_tasks = [perform_search(q) for q in search_queries]
    search_responses = await asyncio.gather(*search_tasks)

    all_results_text = []
    for tavily_resp in search_responses:
        if not tavily_resp:
            continue
        # Flatten into readable text for the LLM
        for r in tavily_resp.get("results", []):
            all_results_text.append(
                f"SOURCE: {r.get('url', '')}\n"
                f"TITLE: {r.get('title', '')}\n"
                f"CONTENT: {r.get('content', '')[:600]}\n"
            )
        if tavily_resp.get("answer"):
            all_results_text.append(f"SUMMARY: {tavily_resp['answer']}\n")

    if not all_results_text:
        raise HTTPException(status_code=503, detail="All Tavily searches failed — check TAVILY_API_KEY")

    combined_results = "\n---\n".join(all_results_text)

    # ── Step 3: Load prompt and inject context ─────────────────────────────
    with open("prompts/lead_finder_prompt.txt", "r") as f:
        prompt_template = f.read()

    prompt = prompt_template.format(
        startup_name=req.startup_name,
        startup_idea=req.startup_idea,
        startup_stage=req.startup_stage,
        target_customer=req.target_customer,
        search_results=combined_results[:12000],  # stay within context
    )

    # ── Step 4: Gemini call (non-streaming — we need structured JSON) ──────
    raw_leads_json = None

    # Try Gemini first
    try:
        model = genai.GenerativeModel("gemini-2.0-flash")
        response = await asyncio.to_thread(model.generate_content, prompt)
        raw_leads_json = response.text
    except Exception as e:
        print(f"Gemini /find-leads failed: {e}")

    # Groq fallback
    if not raw_leads_json:
        try:
            groq_resp = await asyncio.to_thread(
                groq_client.chat.completions.create,
                model="llama-3.3-70b-versatile",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=3000,
            )
            raw_leads_json = groq_resp.choices[0].message.content
        except Exception as e:
            print(f"Groq /find-leads fallback failed: {e}")

    if not raw_leads_json:
        raise HTTPException(status_code=503, detail="All LLMs failed for lead finding")

    # ── Step 5: Parse and return ───────────────────────────────────────────
    try:
        leads = _extract_json(raw_leads_json)
        return {"leads": leads, "search_queries_run": search_queries}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to parse LLM JSON output: {str(e)}. Raw: {raw_leads_json[:500]}"
        )


# ════════════════════════════════════════════════════════════════════════════
# ENDPOINT 2: POST /find-investors
# Discovers real active investors using Tavily + Gemini
# ════════════════════════════════════════════════════════════════════════════

@app.post("/find-investors")
async def find_investors(req: InvestorFinderRequest):
    """
    Runs targeted Tavily searches for investors active in this founder's
    sector + stage, returns a prioritised, structured list.
    """
    # Map stage to search terms
    stage_map = {
        "Idea Stage":  "pre-seed angel",
        "Pre-seed":    "pre-seed angel seed",
        "Seed":        "seed early stage",
        "Series A":    "series A growth",
    }
    stage_term = stage_map.get(req.startup_stage, "early stage seed")

    # Infer sector from idea (simple keyword matching — good enough)
    idea_lower = req.startup_idea.lower()
    sector_hints = []
    if any(w in idea_lower for w in ["saas", "software", "app", "platform", "tool"]):
        sector_hints.append("SaaS")
    if any(w in idea_lower for w in ["ai", "ml", "model", "gpt", "llm"]):
        sector_hints.append("AI")
    if any(w in idea_lower for w in ["b2b", "enterprise", "business"]):
        sector_hints.append("B2B")
    if any(w in idea_lower for w in ["consumer", "b2c", "user", "mobile"]):
        sector_hints.append("consumer")
    if not sector_hints:
        sector_hints = ["startup"]

    sector_str = " ".join(sector_hints)

    search_queries = [
        f"{req.geography} {stage_term} investors {sector_str} 2025 2026 portfolio",
        f"active angel investors {req.geography} {sector_str} {stage_term} funding",
        f"VC funds {req.geography} investing {sector_str} early stage 2026",
        f"Indian startup investors {sector_str} solo founders backing",
    ]

    # ── Run Tavily searches in parallel ──
    async def perform_search(query):
        try:
            res = await asyncio.to_thread(
                tavily_client.search,
                query=query,
                search_depth="advanced",
                max_results=7,
                include_answer=True,
            )
            return res
        except Exception as e:
            print(f"Tavily investor search failed for '{query}': {e}")
            return None

    search_tasks = [perform_search(q) for q in search_queries]
    search_responses = await asyncio.gather(*search_tasks)

    all_results_text = []
    for tavily_resp in search_responses:
        if not tavily_resp:
            continue
        for r in tavily_resp.get("results", []):
            all_results_text.append(
                f"SOURCE: {r.get('url', '')}\n"
                f"TITLE: {r.get('title', '')}\n"
                f"CONTENT: {r.get('content', '')[:700]}\n"
            )
        if tavily_resp.get("answer"):
            all_results_text.append(f"SUMMARY: {tavily_resp['answer']}\n")

    if not all_results_text:
        raise HTTPException(status_code=503, detail="All Tavily searches failed")

    combined_results = "\n---\n".join(all_results_text)

    with open("prompts/investor_finder_prompt.txt", "r") as f:
        prompt_template = f.read()

    prompt = prompt_template.format(
        startup_name=req.startup_name,
        startup_idea=req.startup_idea,
        startup_stage=req.startup_stage,
        mrr=req.mrr,
        user_count=req.user_count,
        search_results=combined_results[:12000],
    )

    raw_investors_json = None

    try:
        model = genai.GenerativeModel("gemini-2.0-flash")
        response = await asyncio.to_thread(model.generate_content, prompt)
        raw_investors_json = response.text
    except Exception as e:
        print(f"Gemini /find-investors failed: {e}")

    if not raw_investors_json:
        try:
            groq_resp = await asyncio.to_thread(
                groq_client.chat.completions.create,
                model="llama-3.3-70b-versatile",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=3000,
            )
            raw_investors_json = groq_resp.choices[0].message.content
        except Exception as e:
            print(f"Groq /find-investors fallback failed: {e}")

    if not raw_investors_json:
        raise HTTPException(status_code=503, detail="All LLMs failed for investor finding")

    try:
        investors = _extract_json(raw_investors_json)
        return {"investors": investors, "search_queries_run": search_queries}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to parse investor JSON: {str(e)}. Raw: {raw_investors_json[:500]}"
        )


# ════════════════════════════════════════════════════════════════════════════
# ENDPOINT 3: POST /enrich-investor
# Pulls real-time news + activity for a single investor in the pipeline
# ════════════════════════════════════════════════════════════════════════════

@app.post("/enrich-investor")
async def enrich_investor(req: InvestorEnrichRequest):
    """
    Given an investor already in the pipeline, fetches their latest activity
    and generates a relevance summary + suggested next action.
    """
    search_queries = [
        f"{req.investor_name} {req.firm} latest investment 2025 2026",
        f"{req.investor_name} interview thoughts startup advice",
        f"{req.firm} portfolio news funding announcement 2026",
    ]

    # ── Run Tavily searches in parallel ──
    async def perform_search(query):
        try:
            res = await asyncio.to_thread(
                tavily_client.search,
                query=query,
                search_depth="advanced",
                max_results=5,
                include_answer=False,
            )
            return res
        except Exception as e:
            print(f"Tavily enrich failed for '{query}': {e}")
            return None

    search_tasks = [perform_search(q) for q in search_queries]
    search_responses = await asyncio.gather(*search_tasks)

    all_results_text = []
    for tavily_resp in search_responses:
        if not tavily_resp:
            continue
        for r in tavily_resp.get("results", []):
            all_results_text.append(
                f"SOURCE: {r.get('url', '')}\n"
                f"TITLE: {r.get('title', '')}\n"
                f"CONTENT: {r.get('content', '')[:500]}\n"
            )

    if not all_results_text:
        return {
            "recent_activity": "No recent news found.",
            "relevance_note": "Consider searching manually on LinkedIn.",
            "suggested_action": "Send a cold intro referencing their firm's thesis.",
            "sources": [],
        }

    combined = "\n---\n".join(all_results_text)

    enrich_prompt = f"""You are helping a founder prepare to approach an investor.

INVESTOR: {req.investor_name} at {req.firm}
FOUNDER'S STARTUP: {req.startup_name} — {req.startup_idea}

RECENT WEB SEARCH RESULTS ABOUT THIS INVESTOR:
{combined[:6000]}

Write a concise investor intelligence briefing. Return ONLY valid JSON:
{{{{
  "recent_activity": "2-3 sentence summary of their most recent notable activity, investments, or public statements",
  "relevance_note": "1-2 sentences on WHY this investor specifically could be interested in this startup",
  "suggested_action": "Specific next step — what to say, what to reference, which platform to use",
  "best_hook": "One sentence opening line for a cold outreach that references something specific from the search results",
  "sources": ["url1", "url2"]
}}}}

Only use what you found in the search results. Do NOT invent facts."""

    raw = None
    try:
        model = genai.GenerativeModel("gemini-2.0-flash")
        response = await asyncio.to_thread(model.generate_content, enrich_prompt)
        raw = response.text
    except Exception as e:
        print(f"Gemini /enrich-investor failed: {e}")

    if not raw:
        try:
            groq_resp = await asyncio.to_thread(
                groq_client.chat.completions.create,
                model="llama-3.3-70b-versatile",
                messages=[{"role": "user", "content": enrich_prompt}],
                max_tokens=1000,
            )
            raw = groq_resp.choices[0].message.content
        except Exception as e:
            print(f"Groq /enrich-investor fallback failed: {e}")

    if not raw:
        return {
            "recent_activity": "LLM unavailable.",
            "relevance_note": "",
            "suggested_action": "Try again shortly.",
            "best_hook": "",
            "sources": [],
        }

    try:
        cleaned = re.sub(r"```(?:json)?", "", raw).strip().rstrip("`").strip()
        # Find the {...} object
        start = cleaned.find("{")
        end   = cleaned.rfind("}") + 1
        result = json.loads(cleaned[start:end])
        return result
    except Exception as e:
        return {
            "recent_activity": raw[:300],
            "relevance_note": "Parse error — raw response returned.",
            "suggested_action": "",
            "best_hook": "",
            "sources": [],
        }


# ════════════════════════════════════════════════════════════════════════════
# ENDPOINT 4: POST /generate-outreach-email
# Generates a cold email for a specific lead (called per-lead from the queue)
# Replaces the old /outreach endpoint's single-shot approach
# ════════════════════════════════════════════════════════════════════════════

class OutreachEmailRequest(BaseModel):
    startup_name: str
    startup_idea: str
    founder_name: str
    target_company: str
    target_domain: Optional[str] = ""
    decision_maker_title: Optional[str] = ""
    fit_reason: Optional[str] = ""
    budget_signal: Optional[str] = ""

@app.post("/generate-outreach-email")
async def generate_outreach_email(req: OutreachEmailRequest):
    """
    Generates a single highly-personalised cold email for one lead.
    Called once per lead when the founder queues outreach.
    """
    # Quick Tavily search for any extra context on this specific company
    extra_context = ""
    try:
        tavily_resp = await asyncio.to_thread(
            tavily_client.search,
            query=f"{req.target_company} latest news product 2026",
            search_depth="basic",
            max_results=3,
        )
        snippets = [r.get("content", "")[:300] for r in tavily_resp.get("results", [])]
        extra_context = "\n".join(snippets)
    except Exception:
        pass  # non-fatal

    with open("prompts/cold_email_prompt.txt", "r") as f:
        base_template = f.read()

    # Extend the cold email prompt with lead-specific context
    prompt = f"""{base_template}

SPECIFIC LEAD CONTEXT (use this to personalise):
- Target company: {req.target_company} ({req.target_domain})
- Decision-maker to address: {req.decision_maker_title}
- Why this company is a fit: {req.fit_reason}
- Budget signal / trigger: {req.budget_signal}
- Extra research: {extra_context[:800] if extra_context else "None found"}

FOUNDER DETAILS:
- Name: {req.founder_name}
- Startup: {req.startup_name}
- What it does: {req.startup_idea}

Write ONE cold email subject line and body.
Return as JSON: {{{{"subject": "...", "body": "..."}}}}
Keep the body under 150 words. Be specific, not generic. Reference the budget signal naturally."""

    raw = None
    try:
        model = genai.GenerativeModel("gemini-2.0-flash")
        raw = (await asyncio.to_thread(model.generate_content, prompt)).text
    except Exception as e:
        print(f"Gemini /generate-outreach-email failed: {e}")

    if not raw:
        try:
            groq_resp = await asyncio.to_thread(
                groq_client.chat.completions.create,
                model="llama-3.3-70b-versatile",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=800,
            )
            raw = groq_resp.choices[0].message.content
        except Exception as e:
            print(f"Groq fallback failed: {e}")

    if not raw:
        raise HTTPException(status_code=503, detail="All LLMs failed for email generation")

    try:
        cleaned = re.sub(r"```(?:json)?", "", raw).strip().rstrip("`").strip()
        start = cleaned.find("{")
        end   = cleaned.rfind("}") + 1
        result = json.loads(cleaned[start:end])
        return result
    except Exception:
        return {"subject": "Quick question", "body": raw[:400]}