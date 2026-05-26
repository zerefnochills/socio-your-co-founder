import os
import pytest
from fastapi.testclient import TestClient

# Force Mock Mode for testing to bypass external API calls
os.environ["MOCK_MODE"] = "True"
os.environ["TESTING"] = "True"

# Set mock API keys so standard startup logic succeeds
if not os.environ.get("GEMINI_API_KEY"):
    os.environ["GEMINI_API_KEY"] = "mock-gemini-key"
if not os.environ.get("GROQ_API_KEY"):
    os.environ["GROQ_API_KEY"] = "mock-groq-key"
if not os.environ.get("TAVILY_API_KEY"):
    os.environ["TAVILY_API_KEY"] = "mock-tavily-key"

from main import app

@pytest.fixture(scope="module")
def client():
    """Provides a TestClient targeting the FastAPI application running in Mock Mode."""
    with TestClient(app) as c:
        yield c
