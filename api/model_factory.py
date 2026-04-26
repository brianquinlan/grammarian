from pydantic_ai.models.google import GoogleModel
from pydantic_ai.providers.google import GoogleProvider
from pydantic_ai.models.openai import OpenAIChatModel
from pydantic_ai.providers.openai import OpenAIProvider


AVAILABLE_MODELS = {
    "Gemini 3.1 Pro": "gemini-3.1-pro-preview",
    "Gemini 3 Flash": "gemini-3-flash",
    "GPT-5.5": "gpt-5.5",
    "GPT-5 Pro": "gpt-5-pro",
}

DEFAULT_MODEL = "gemini-3-flash"

def get_model(model_name: str | None = None) -> GoogleModel | OpenAIChatModel:
    if not model_name:
        model_name = DEFAULT_MODEL
    
    if model_name.startswith("gpt"):
        provider = OpenAIProvider()
        return OpenAIChatModel(model_name, provider=provider)
    else:
        provider = GoogleProvider()
        return GoogleModel(model_name, provider=provider)
