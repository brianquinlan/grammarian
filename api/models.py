import datetime
import enum
from typing import Annotated, TextIO

from pydantic import BaseModel, Field, StringConstraints
from pydantic_ai import ModelMessage
from termcolor import colored


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
    FIFTH = "5th"
    SIXTH = "6th"
    SEVENTH = "7th"
    EIGHTH = "8th"
    NINTH = "9th"


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
        f.write(
            f"""{title(self.name)} {self.school.value} {self.level.value}

{field("Casting Time:")} {self.casting_time}
{field("Range:")} {self.range}
{field("Components:")} {self.components}
{field("Duration:")} {self.duration}

{self.description}
"""
        )


class RingOfTheGrammarianSpell(BaseModel):
    original_spell_name: str = Field(
        description='The spell used to generate the new spell, e.g. "Cause Fear".'
    )

    grammarian_spell: Spell = Field(
        description="The spell that can be cast using the Ring of the Grammarian."
    )

    def write_to_file(self, f: TextIO):
        def field(t):
            return colored(t, "black", attrs=["bold"]) if f.isatty() else t

        title = field
        f.write(
            f"""{title(self.grammarian_spell.name)} {self.grammarian_spell.school.value} {self.grammarian_spell.level.value}

{field("Casting Time:")} {self.grammarian_spell.casting_time}
{field("Range:")} {self.grammarian_spell.range}
{field("Components:")} {self.grammarian_spell.components}
{field("Duration:")} {self.grammarian_spell.duration}
{field("Derived From:")} {self.original_spell_name}

{self.grammarian_spell.description}
"""
        )


class SageOfTheGrammarianAnswer(BaseModel):
    answer_description: Annotated[
        str,
        StringConstraints(min_length=30, max_length=200),
    ] = Field(description='A description of the reasoning used to produce the ' 
              'spells suggested by the sage. May include a description of the '
              'assumptions made (such as character class or level) by the sage.')
    grammarian_spells: list[RingOfTheGrammarianSpell] = Field(
        description="The spells suggested by the sage."
    )


class UserPrompt(BaseModel):
    text: str


class AppResponse(BaseModel):
    sage_answer: SageOfTheGrammarianAnswer


class Conversation(BaseModel):
    conversation_id: str
    created_on: datetime.datetime = Field(default_factory=datetime.datetime.now)
    name: str = ""
    model: str = ""
    all_messages: list[ModelMessage] = []
    dialog: list[UserPrompt | AppResponse] = []


# API results


class ConversationSummary(BaseModel):
    conversation_id: str
    created_on: datetime.datetime
    name: str


class ListConversationsResponse(BaseModel):
    conversations: list[ConversationSummary]


class PromptResponse(BaseModel):
    conversation_id: str
    sage_answer: SageOfTheGrammarianAnswer
