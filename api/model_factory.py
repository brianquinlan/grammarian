from pydantic_ai.models.google import GoogleModel
from pydantic_ai.providers.google import GoogleProvider


AVAILABLE_MODELS = {
    "Gemini 3 Pro": "gemini-3-pro-preview",
    "Gemini 3 Flash": "gemini-3-flash-preview",
}

def get_model(model_name: str | None = None) -> GoogleModel:
    if not model_name:
        model_name = "gemini-3-flash-preview"
    provider = GoogleProvider()
    return GoogleModel(model_name, provider=provider)
