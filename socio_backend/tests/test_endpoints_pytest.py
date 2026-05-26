import json
import pytest

def test_health(client):
    """Test the /health endpoint to ensure configuration is active and live."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "keys_configured" in data
    assert data["keys_configured"]["gemini"] is True

def test_chat_sse_stream(client):
    """Test the main /chat endpoint, verifying the custom SSE stream and mood chunk structure."""
    payload = {
        "message": "I'm feeling really overwhelmed about our product launch tomorrow.",
        "founder_name": "Ayush Kumar",
        "context": {
            "startup_name": "Socio AI",
            "startup_idea": "Emotionally intelligent AI co-founder for solo founders.",
            "startup_stage": "Pre-seed",
            "mrr": "0",
            "user_count": "150"
        },
        "chat_history": [
            {"role": "user", "content": "Hi Socio!"},
            {"role": "socio", "content": "Hey there! Ready to build?"}
        ]
    }
    
    with client.stream("POST", "/chat", json=payload) as response:
        assert response.status_code == 200
        assert "text/event-stream" in response.headers["content-type"].lower()
        
        events = []
        for line in response.iter_lines():
            if line.strip().startswith("data: "):
                data_str = line.strip()[6:]
                try:
                    event = json.loads(data_str)
                    events.append(event)
                except json.JSONDecodeError:
                    continue
        
        # Verify the structure of the event stream
        assert len(events) >= 3
        
        # 1. The first event must contain the classified mood data
        assert events[0]["type"] == "mood"
        mood_data = events[0]["data"]
        assert "emotion" in mood_data
        assert "needs_sos" in mood_data
        assert "persona_weights" in mood_data
        assert "skeptic" in mood_data["persona_weights"]
        assert "hustler" in mood_data["persona_weights"]
        assert "strategist" in mood_data["persona_weights"]
        
        # 2. Intermediate events must be streaming text chunks
        text_chunks = [e for e in events if e["type"] == "text"]
        assert len(text_chunks) > 0
        full_text = "".join([chunk["data"] for chunk in text_chunks])
        assert "MVP" in full_text or "co-founder" in full_text
        
        # 3. The final event must be the done status signal
        assert events[-1]["type"] == "done"

def test_outreach_generation(client):
    """Test the /outreach endpoint cold email and script generation."""
    payload = {
        "target_name": "Sundar Pichai",
        "target_company": "Google",
        "target_role": "CEO",
        "context": {
            "startup_name": "Socio AI",
            "startup_idea": "AI co-founder workspace",
            "startup_stage": "Pre-seed",
            "mrr": "0",
            "user_count": "150"
        },
        "ask": "a quick feedback call",
        "traction": "200 daily active users"
    }
    response = client.post("/outreach", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "cold_email" in data
    assert "call_script" in data
    assert "followups" in data
    assert "research_used" in data
    
    # Assert JSON schema matches cold_email rules
    assert "subject" in data["cold_email"]
    assert "body" in data["cold_email"]
    assert "ps" in data["cold_email"]
    assert "permission_opener" in data["call_script"]
    assert "day_3" in data["followups"]

def test_investor_followup(client):
    """Test the /investor-followup endpoint generated mailings."""
    payload = {
        "investor_name": "Kunal Shah",
        "investor_firm": "QED Partners",
        "meeting_notes": "Discussed initial SaaS GTM and scaling metrics",
        "days_since_contact": 6,
        "status": "pitching",
        "context": {
            "startup_name": "Socio AI",
            "startup_idea": "AI Co-Founder"
        },
        "traction": "$10k ARR"
    }
    response = client.post("/investor-followup", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "subject" in data
    assert "body" in data
    assert "send_as_reply" in data
    assert "follow_up_recommended_in_days" in data
    assert "tone_note" in data
    assert data["send_as_reply"] is True

def test_stress_test(client):
    """Test the /stress-test endpoint analysis."""
    payload = {
        "idea": "An AI co-founder helper tool",
        "context": {
            "startup_name": "Socio AI",
            "startup_stage": "Idea Stage"
        }
    }
    response = client.post("/stress-test", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "analysis" in data
    assert "Verdict" in data["analysis"]

def test_find_leads(client):
    """Test the /find-leads customer discovery endpoint."""
    payload = {
        "startup_name": "Socio AI",
        "startup_idea": "An emotionally intelligent AI co-founder for solo founders.",
        "startup_stage": "Pre-seed",
        "target_customer": "SaaS startup founders with small remote teams",
        "num_search_rounds": 2
    }
    response = client.post("/find-leads", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "leads" in data
    assert "search_queries_run" in data
    assert len(data["leads"]) > 0
    top_lead = data["leads"][0]
    assert "company" in top_lead
    assert "domain" in top_lead
    assert "fit_reason" in top_lead
    assert "decision_maker_title" in top_lead
    assert "priority_score" in top_lead

def test_find_investors(client):
    """Test the /find-investors pipeline matching endpoint."""
    payload = {
        "startup_name": "Socio AI",
        "startup_idea": "An emotionally intelligent AI co-founder for solo founders.",
        "startup_stage": "Pre-seed",
        "mrr": "0",
        "user_count": "150",
        "geography": "India"
    }
    response = client.post("/find-investors", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "investors" in data
    assert "search_queries_run" in data
    assert len(data["investors"]) > 0
    investor = data["investors"][0]
    assert "investor_name" in investor
    assert "firm" in investor
    assert "fit_reason" in investor
    assert "priority_score" in investor

def test_enrich_investor(client):
    """Test the /enrich-investor intelligence endpoint."""
    payload = {
        "investor_name": "Kunal Shah",
        "firm": "QED Partners",
        "startup_name": "Socio AI",
        "startup_idea": "AI Co-Founder app"
    }
    response = client.post("/enrich-investor", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "recent_activity" in data
    assert "relevance_note" in data
    assert "suggested_action" in data
    assert "best_hook" in data
    assert "sources" in data

def test_generate_outreach_email(client):
    """Test the /generate-outreach-email outreach drafting endpoint."""
    payload = {
        "startup_name": "Socio AI",
        "startup_idea": "An emotionally intelligent AI co-founder for solo founders.",
        "founder_name": "Ayush Kumar",
        "target_company": "Linear",
        "target_domain": "linear.app",
        "decision_maker_title": "Head of Product",
        "fit_reason": "Linear is highly developer and founder focused.",
        "budget_signal": "Recently raised Series B funding"
    }
    response = client.post("/generate-outreach-email", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "subject" in data
    assert "body" in data
    assert "Linear" in data["subject"] or "Linear" in data["body"]

def test_competitor_radar(client):
    """Test the /competitor-radar business landscape scanning endpoint."""
    payload = {
        "idea": "An emotionally intelligent AI co-founder for solo founders.",
        "company_name": "Socio AI"
    }
    response = client.post("/competitor-radar", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "competitors" in data
    assert "search_queries_run" in data
    assert len(data["competitors"]) > 0
    competitor = data["competitors"][0]
    assert "name" in competitor
    assert "description" in competitor
    assert "threat_level" in competitor
    assert "differentiator" in competitor

def test_auto_setup_investor_pipeline(client):
    """Test the /auto-setup-investor-pipeline bulk integration endpoint."""
    payload = {
        "startup_name": "Socio AI",
        "startup_idea": "An emotionally intelligent AI co-founder for solo founders.",
        "startup_stage": "Pre-seed",
        "mrr": "0",
        "user_count": "150",
        "geography": "India",
        "top_n": 3
    }
    response = client.post("/auto-setup-investor-pipeline", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "pipeline_investors" in data
    assert "all_discovered" in data
    assert "search_queries_run" in data
    assert len(data["pipeline_investors"]) > 0
    investor = data["pipeline_investors"][0]
    assert "investor_name" in investor
    assert "enrichment_summary" in investor
