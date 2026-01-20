from pydantic import constr
from pydantic_ai import Agent
from pydantic_ai.models import Model


async def title_conversation(model: Model, description: str, existing_titles: list[str]) -> str:
    agent = Agent(model, output_type=constr(min_length=10, max_length=30))

    response = await agent.run(f"""
Generate a clever and succinct title for a conversation that begins with this prompt:
{description}

Your title should be distinct from the following existing titles:
{', '.join(existing_titles)}""")
    return response.output