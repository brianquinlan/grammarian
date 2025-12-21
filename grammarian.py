import argparse
import string
import sys
from typing import Generator

from pydantic_ai import Agent, Tool
from pydantic_ai.models import Model
from typing import TextIO
from pydantic import BaseModel

from termcolor import colored

from model_factory import get_model

import models

_LETTERS = string.ascii_lowercase
_WORDS = set(w.lower().strip() for w in open("words.txt").readlines())


class RingOfTheGrammarianSpell(BaseModel):
    """The spell used to generate the new spell, e.g. "Cause Fear"."""

    original_spell_name: str

    """The spell that can be cast using the Ring of the Grammarian."""
    grammarian_spell: models.Spell

    def write_to_file(self, f: TextIO):
        def field(t):
            return colored(t, "black", attrs=["bold"]) if f.isatty() else t

        title = field
        f.write(f"""{title(self.grammarian_spell.name)} {self.grammarian_spell.school.value} {self.grammarian_spell.level.value}

{field("Casting Time:")} {self.grammarian_spell.casting_time}
{field("Range:")} {self.grammarian_spell.range}
{field("Components:")} {self.grammarian_spell.components}
{field("Duration:")} {self.grammarian_spell.duration}
{field("Derived From:")} {self.original_spell_name}

{self.grammarian_spell.description}
""")


_SYSTEM_PROMPT = """
The Ring of the Grammarian is a ring that allows the wearer to change one
letter of a Dungeons & Dragons spell name, giving the spell a different effect.

The Ring of the Grammarian can be used, once per day, to alter one letter
in a spell title, as you're casting it, for a different effect.
For instance, the wearer can start casting Cause Fear and activate the ring
to instead cast Cause Bear.

You are a creative agent whose job is to find a spell that can solve a problem
posed by the user. You cannot use a spell name that is already defined by the
rules of Dungeon's and Dragons.

Instead, you must use the rules of the Ring of the Grammarian to invent a new spell that
has the effect that the user wants. All possible spell names will be provided
by the given `spell_variations_as_dict` function.

The function, level, school, duration and range of the original spell has no influence
on the new spell. Determine the level, school, duration and range of the new spell
yourself based on the user's prompt and your knowledge of other Dungeons and Dragon's
spells.

The best approach is to start with all possible spells available to the owner of the ring
and then use `spell_variations_as_dict` to generate all possible variations of those spells.
It is important to generate as many variations as possible so provide as much input to
`spell_variations_as_dict` as possible.

Unless otherwise instructed, assume that the owner of the ring is able to use any spell
available to their class from the Player's Handbook and other official sources.

Make sure that proposed spells are consistent with existing Dungeons and Dragons spells in
terms of spell level, duration, and range. 

Unless otherwise specified, you should propose multiple spell variations.
"""


def single_letter_changes_for_word(word: str, allow_remove=False, allow_add=False):
    word = word.lower()
    for i in range(len(word)):
        if allow_remove:
            yield word[:i] + word[i + 1 :]

        for l in _LETTERS:
            if word[i] != l:
                # Replace a letter
                yield word[:i] + l + word[i + 1 :]
                if allow_add:
                    yield word[:i] + l + word[i:]


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


def find_spells(
    model: Model, description: str, name: str | None = None
) -> list[RingOfTheGrammarianSpell]:
    agent = Agent(
        model,
        system_prompt=_SYSTEM_PROMPT,
        output_type=list[RingOfTheGrammarianSpell],
        tools=[
            Tool(spell_variations_as_dict, takes_ctx=False),
        ],
    )
    response = agent.run_sync(description)

    return response.output


def main():
    parser = argparse.ArgumentParser(description="What the program does")
    parser.add_argument("-d", "--description")
    args = parser.parse_args()
    model = get_model()

    for spell in find_spells(model, args.description):
        spell.write_to_file(sys.stdout)
        sys.stdout.write("\n")


if __name__ == "__main__":
    main()
