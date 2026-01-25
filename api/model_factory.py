from pydantic_ai.models.google import GoogleModel
from pydantic_ai.providers.google import GoogleProvider
from pydantic_ai.models.openai import OpenAIChatModel
from pydantic_ai.providers.openai import OpenAIProvider


AVAILABLE_MODELS = {
    "Gemini 3 Pro": "gemini-3-pro-preview",
    "Gemini 3 Flash": "gemini-3-flash-preview",
    "GPT-5.2": "gpt-5.2",
    "GPT-5 mini": "gpt-5-mini",
}

def get_model(model_name: str | None = None) -> GoogleModel | OpenAIChatModel:
    if not model_name:
        model_name = "gemini-3-flash-preview"
    
    if model_name.startswith("gpt"):
        provider = OpenAIProvider()
        return OpenAIChatModel(model_name, provider=provider)
    else:
        provider = GoogleProvider()
        return GoogleModel(model_name, provider=provider)
