async def title_conversation(description: str, existing_titles: list[str]) -> str:
    return description[:30]