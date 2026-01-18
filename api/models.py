import enum
from typing import TextIO

from dataclasses import field
from pydantic_ai import ModelMessage
from termcolor import colored
from pydantic import BaseModel


class School(enum.Enum):
    ABJURATION = "Abjuration"
    CONJURATION = "Conjuration"
    DIVINATION = "Divination"
    ENCHANTMENT = "Enchantment"
    EVOCATION = "Evocation"
    ILLUSION = "Illusion"
    NECROMANCY = "Necromancy"
    TRANSMUTATION = "Transmutation"


class Level(enum.Enum):
    CANTRIP = "Cantrip"
    FIRST = "1st"
    SECOND = "2nd"
    THIRD = "3rd"
    FOURTH = "4th"
    FIVE = "5th"
    SIX = "6th"
    SEVEN = "7th"
    EIGHT = "8th"
    NINE = "9th"


class Spell(BaseModel):
    name: str
    school: School
    level: Level
    casting_time: str
    range: str
    components: str

    """
    The duration of the spell.

    For example, 'Concentration, up to 1 minute' or 'Instantaneous'.
    """
    duration: str
    description: str

    def write_to_file(self, f: TextIO):
        def field(t):
            return colored(t, "black", attrs=["bold"]) if f.isatty() else t

        title = field
        f.write(f"""{title(self.name)} {self.school.value} {self.level.value}

{field("Casting Time:")} {self.casting_time}
{field("Range:")} {self.range}
{field("Components:")} {self.components}
{field("Duration:")} {self.duration}

{self.description}
""")


class RingOfTheGrammarianSpell(BaseModel):
    """The spell used to generate the new spell, e.g. "Cause Fear"."""

    original_spell_name: str

    """The spell that can be cast using the Ring of the Grammarian."""
    grammarian_spell: Spell

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


class PromptResponse(BaseModel):
    conversation_id: str
    spells: list[RingOfTheGrammarianSpell] = field(default_factory=list)


class UserPrompt(BaseModel):
    text: str

class AppResponse(BaseModel):
    spells: list[RingOfTheGrammarianSpell] = field(default_factory=list)

class Conversation(BaseModel):
    conversation_id: str
    model: str = ''
    all_messages : list[ModelMessage] = []
    dialog: list[UserPrompt | AppResponse] = []
