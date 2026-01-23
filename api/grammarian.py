import argparse
import asyncio
import dataclasses
import string
import sys
from typing import Generator, Tuple

import models
from model_factory import get_model
from pydantic_ai import Agent, ModelMessage, RunContext, Tool
from pydantic_ai.models import Model

_LETTERS = string.ascii_lowercase
_WORDS = set(w.lower().strip() for w in open("words.txt").readlines())


_SYSTEM_PROMPT = """
You are a wise sage and your special area of knowledge is the Ring of the Grammarian.
People come to you for advice on how to solve their problems using their
Rings of the Grammarian.

The Ring of the Grammarian is a ring that allows the wearer to change one
letter of a Dungeons & Dragons spell name, giving the spell a different effect.

The Ring of the Grammarian can be used, once per day, to alter one letter
in a spell title, as you're casting it, for a different effect.
For instance, the wearer can start casting "Cause Fear" and activate the ring
to instead cast "Cause Bear".

You cannot use a spell name that is already defined by the rules of Dungeon's and
Dragons.

Instead, you must use the rules of the Ring of the Grammarian to invent a new spell that
has the wanted effect. All possible spell names will be provided
by the given `spell_variations_as_dict` function.

The function, level, school, duration and range of the original spell has no influence
on the new spell. Determine the school, duration and range of the new spell
yourself based on the situation and your knowledge of other Dungeons and Dragon's
spells. Determine the level of the new spell based on the `determine_level` function.
If the prompt contains level constraints then you MUST use `determine_level` to determine
the level of the new spell.

The best approach is to start with all possible spells available to the owner of the ring
and then use `spell_variations_as_dict` to generate all possible variations of those spells.
It is important to generate as many variations as possible so provide as much input to
`spell_variations_as_dict` as possible. If no spell restrictions are provide, ask for the
variations for every spell in Dungeons & Dragons.

Unless otherwise instructed, assume that the owner of the ring is able to use any spell
available to their class from the Player's Handbook and other official sources.

Make sure that proposed spells are consistent with existing Dungeons and Dragons spells in
terms of spell level, duration, and range. In the description, make sure to include the what
effect upcasting the spell has or, if it is a cantrip, what it does at higher levels.

Unless otherwise specified, you should propose multiple spell variations.
"""

_LEVELING_SYSTEM_PROMPT = """You are an expert designer of Dungeons & Dragons spells.

You have an expert understanding of existing Dungeons & Dragons spells and
can correctly determine the appropriate level for a new spell based on the
precedent provided by existing spells.
"""


def single_letter_changes_for_word(word: str, allow_remove=False, allow_add=False):
    word = word.lower()
    for i in range(len(word)):
        if allow_remove:
            yield word[:i] + word[i + 1 :]

        for letter in _LETTERS:
            if word[i] != letter:
                # Replace a letter
                yield word[:i] + letter + word[i + 1 :]
                if allow_add:
                    yield word[:i] + letter + word[i:]


def single_letter_changes_for_text(text: str):
    words = [w.lower() for w in text.split(" ")]
    for i, word in enumerate(words):
        for word_variation in single_letter_changes_for_word(word):
            yield " ".join(words[:i] + [word_variation] + words[i + 1 :])


def spell_variations(name: str) -> Generator[str, None, None]:
    """Generate all possible variations of the given spell name.

    Generate all possible variations of the given spell name according to the
    rules of the Ring of the Grammarian.

    >>> sorted(list(spell_variations('cat')))
    ['at', 'bat']
    """
    for variation in single_letter_changes_for_text(name):
        if set(variation.split(" ")) <= _WORDS:
            yield variation


def spell_variations_as_dict(names: list[str]) -> dict[str, list[str]]:
    """Generate all possible variations of the given spell names.

    Generate all possible variations of the given spell names according to the
    rules of the Ring of the Grammarian and return them as a dictionary whose
    keys are the original spell names and whose values are lists of variations.

    >>> spell_variations_as_dict(['cat', 'dog'])
    {'cat': ['at', 'bat'], 'dog': ['at', 'bat']}
    """
    print(names)
    return {name: list(spell_variations(name)) for name in names}


@dataclasses.dataclass
class Dependencies:
    agent: Agent[None, models.Level]


async def determine_level(
    ctx: RunContext[Dependencies], spell: models.Spell
) -> models.Level:
    """Determine the casting level of a spell based on the precedent provided by existing spells."""
    json = spell.model_dump_json(exclude={"level", "name"})
    print(json)
    response = await ctx.deps.agent.run(json)
    print(f"{spell.name} should be level {response.output.value}")
    return response.output


async def find_spells(
    model: Model,
    description: str,
    model_messages: list[ModelMessage] | None = [],
) -> Tuple[list[ModelMessage], models.SageOfTheGrammarianAnswer]:
    leveling_agent = Agent(
        model,
        system_prompt=_LEVELING_SYSTEM_PROMPT,
        output_type=models.Level,
    )
    agent = Agent(
        model,
        system_prompt=_SYSTEM_PROMPT,
        output_type=models.SageOfTheGrammarianAnswer,
        deps_type=Dependencies,
        tools=[
            Tool(spell_variations_as_dict, takes_ctx=False),
            Tool(determine_level, takes_ctx=True),
        ],
    )

    response = await agent.run(
        description,
        message_history=model_messages,
        deps=Dependencies(agent=leveling_agent),
    )
    return response.all_messages(), response.output
