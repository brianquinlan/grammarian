from pydantic_ai import Agent
from pydantic_ai.models import Model

import models

_SYSTEM_PROMPT = """You are an expert designer of Dungeons & Dragons spells.

You have an expert understanding of existing Dungeons & Dragons spells and
can correctly determine the appropriate level for a new spell based on the
precedent provided by existing spells.
"""


def determine_level(model: Model, spell: models.Spell) -> models.Level:
    unleveled_spell = spell.model_copy()
    unleveled_spell.level = models.Level.UNKNOWN

    agent = Agent(model, system_prompt=_SYSTEM_PROMPT, output_type=models.Level)
    response = agent.run_sync(unleveled_spell)

    return response.output
