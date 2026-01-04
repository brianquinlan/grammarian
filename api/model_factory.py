from pydantic_ai.models.google import GoogleModel
from pydantic_ai.providers.google import GoogleProvider

def get_model() -> GoogleModel:
    provider = GoogleProvider()
    return GoogleModel("gemini-3-pro-preview", provider=provider)
