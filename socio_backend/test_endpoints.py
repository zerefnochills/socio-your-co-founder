import urllib.request
import json
import sys

BASE_URL = "http://127.0.0.1:8000"

def post_json(endpoint, data):
    url = f"{BASE_URL}{endpoint}"
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read().decode("utf-8")
            return json.loads(res_body), response.status
    except Exception as e:
        print(f"Error on POST {endpoint}: {e}")
        if hasattr(e, "read"):
            err_body = e.read().decode("utf-8")
            print(f"Error body: {err_body}")
        return None, getattr(e, "code", 500)

def run_tests():
    print("[TEST] Starting Automated Features Integration Test for Socio Backend...")
    print(f"Targeting server: {BASE_URL}\n")

    startup_context = {
        "startup_name": "Socio AI",
        "startup_idea": "An emotionally intelligent AI co-founder for solo founders.",
        "startup_stage": "Pre-seed",
        "mrr": "0",
        "user_count": "150",
    }

    # 1. Test /find-leads
    print("--- 1. Testing /find-leads ---")
    lead_request = {
        "startup_name": "Socio AI",
        "startup_idea": "An emotionally intelligent AI co-founder for solo founders.",
        "startup_stage": "Pre-seed",
        "target_customer": "SaaS startup founders with small remote teams",
        "num_search_rounds": 2
    }
    leads_res, status = post_json("/find-leads", lead_request)
    if leads_res and "leads" in leads_res:
        leads_list = leads_res["leads"]
        print(f"[OK] /find-leads succeeded! Status: {status}")
        print(f"Found {len(leads_list)} leads. Top lead preview:")
        if leads_list:
            top_lead = leads_list[0]
            print(json.dumps(top_lead, indent=2))
        else:
            print("[WARN] Empty leads list returned.")
    else:
        print("[FAIL] /find-leads failed!")
        sys.exit(1)

    print("\n")

    # 2. Test /generate-outreach-email
    print("--- 2. Testing /generate-outreach-email ---")
    if leads_list:
        lead = leads_list[0]
        email_request = {
            "startup_name": "Socio AI",
            "startup_idea": "An emotionally intelligent AI co-founder for solo founders.",
            "founder_name": "Ayush Kumar",
            "target_company": lead.get("company", "Test Company"),
            "target_domain": lead.get("domain") or "testcompany.com",
            "decision_maker_title": lead.get("decision_maker_title", "CEO"),
            "fit_reason": lead.get("fit_reason", "Highly relevant audience for Socio AI"),
            "budget_signal": lead.get("budget_signal", "Hiring sales managers"),
        }
    else:
        email_request = {
            "startup_name": "Socio AI",
            "startup_idea": "An emotionally intelligent AI co-founder for solo founders.",
            "founder_name": "Ayush Kumar",
            "target_company": "Linear",
            "target_domain": "linear.app",
            "decision_maker_title": "Head of Product",
            "fit_reason": "Linear is renowned for high productivity and founder focus",
            "budget_signal": "Recently raised Series B",
        }
    email_res, status = post_json("/generate-outreach-email", email_request)
    if email_res and "subject" in email_res:
        print(f"[OK] /generate-outreach-email succeeded! Status: {status}")
        print(f"Subject: {email_res.get('subject')}")
        print(f"Body: {email_res.get('body')[:200]}...")
    else:
        print("[FAIL] /generate-outreach-email failed!")
        sys.exit(1)

    print("\n")

    # 3. Test /find-investors
    print("--- 3. Testing /find-investors ---")
    investor_request = {
        "startup_name": "Socio AI",
        "startup_idea": "An emotionally intelligent AI co-founder for solo founders.",
        "startup_stage": "Pre-seed",
        "mrr": "0",
        "user_count": "150",
        "geography": "India"
    }
    investors_res, status = post_json("/find-investors", investor_request)
    if investors_res and "investors" in investors_res:
        investors_list = investors_res["investors"]
        print(f"[OK] /find-investors succeeded! Status: {status}")
        print(f"Found {len(investors_list)} investors. Top investor preview:")
        if investors_list:
            top_inv = investors_list[0]
            print(json.dumps(top_inv, indent=2))
        else:
            print("[WARN] Empty investors list returned.")
    else:
        print("[FAIL] /find-investors failed!")
        sys.exit(1)

    print("\n")

    # 4. Test /enrich-investor
    print("--- 4. Testing /enrich-investor ---")
    if investors_list:
        inv = investors_list[0]
        enrich_request = {
            "investor_name": inv.get("investor_name", "Kunal Shah"),
            "firm": inv.get("firm", "QED Partners"),
            "startup_name": "Socio AI",
            "startup_idea": "An emotionally intelligent AI co-founder for solo founders."
        }
    else:
        enrich_request = {
            "investor_name": "Sandeep Nailwal",
            "firm": "Polygon Ventures",
            "startup_name": "Socio AI",
            "startup_idea": "An emotionally intelligent AI co-founder for solo founders."
        }
    enrich_res, status = post_json("/enrich-investor", enrich_request)
    if enrich_res and "recent_activity" in enrich_res:
        print(f"[OK] /enrich-investor succeeded! Status: {status}")
        print(f"Recent Activity: {enrich_res.get('recent_activity')}")
        print(f"Relevance Note: {enrich_res.get('relevance_note')}")
        print(f"Best Hook: {enrich_res.get('best_hook')}")
    else:
        print("[FAIL] /enrich-investor failed!")
        sys.exit(1)

    print("\n[SUCCESS] ALL ENDPOINTS VERIFIED AND WORKING PERFECTLY!")

if __name__ == "__main__":
    run_tests()
