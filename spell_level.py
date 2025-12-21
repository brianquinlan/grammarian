from pydantic_ai import Agent
from pydantic_ai.models import Model

import models

_LEVELING_SYSTEM_PROMPT = """You are an expert designer of Dungeons & Dragons spells.

You have an expert understanding of existing Dungeons & Dragons spells and
can correctly determine the appropriate level for a new spell based on the
precedent provided by existing spells.
"""


def get(model: Model):
    agent = Agent(
        model, system_prompt=_LEVELING_SYSTEM_PROMPT, output_type=models.Level
    )

    async def determine_level(spell: models.Spell) -> models.Level:
        """Determine the casting level of a spell based on the precedent provided by existing spells."""
        unleveled_spell: models.Spell = spell.model_copy()
        unleveled_spell.level = models.Level.UNKNOWN
        print(unleveled_spell.model_dump_json())
        response = await agent.run(unleveled_spell.model_dump_json())
        print(f"{spell.name} should be level {response.output.value}")
        return response.output

    return determine_level
