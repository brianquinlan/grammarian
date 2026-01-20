from pydantic_ai.models import Model

async def title_conversation(model: Model, description: str, existing_titles: list[str]) -> str:
    return description[:30]