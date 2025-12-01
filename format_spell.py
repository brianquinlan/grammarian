import argparse
import sys

from pydantic_ai import Agent
from pydantic_ai.models import Model

from model_factory import get_model


import models

_PROMPT = """
Following this prompt is description of a Dungeons & Dragons 5e spell.

Expand the description to include details typically included in a Dungeons
& Dragons spell description. Modiy the description to follow the writing
conventions typical of a Dungeons & Dragons spell.

If the spell description includes a level or name, use that exactly.

If the spell description does not include information about the spell's level,
use other dungeons and dragons spells as a guide for picking a level. Do not
pick too low a level.

Description:
{description}
"""


def format(
    model:Model, description: str, name: str | None = None
) -> models.Spell:
    agent = Agent(model, output_type=models.Spell)
    response = agent.run_sync(_PROMPT.format(description=description))

    return response.output


def main():
    model = get_model()

    parser = argparse.ArgumentParser(description="What the program does")
    parser.add_argument("-d", "--description")
    args = parser.parse_args()

    spell = format(model, args.description)
    spell.foo(sys.stdout)


if __name__ == "__main__":
    main()
