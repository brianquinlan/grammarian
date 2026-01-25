import datetime
import enum
from typing import Annotated

from pydantic import BaseModel, Field, StringConstraints
from pydantic_ai import ModelMessage


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
    duration : str = Field(description='The duration of the spell. For example, '
                           '"Concentration, up to 1 minute" or "Instantaneous".')
    description: str


class RingOfTheGrammarianSpell(BaseModel):
    original_spell_name: str = Field(
        description='The spell used to generate the new spell, e.g. "Cause Fear".'
    )

    grammarian_spell: Spell = Field(
        description="The spell that can be cast using the Ring of the Grammarian."
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


class AdventurerPrompt(BaseModel):
    utterance: str


class Conversation(BaseModel):
    conversation_id: str
    created_on: datetime.datetime = Field(default_factory=datetime.datetime.now)
    name: str = ""
    model: str = ""
    all_messages: list[ModelMessage] = []
    dialog: list[AdventurerPrompt | SageOfTheGrammarianAnswer] = []


# API results


class ListConversationsResponse(BaseModel):
    class ConversationSummary(BaseModel):
        conversation_id: str
        created_on: datetime.datetime
        name: str

    conversations: list[ConversationSummary]


class CreateOrUpdateConversationResponse(BaseModel):
    conversation_id: str
    sage_answer: SageOfTheGrammarianAnswer


class ListModelsResponse(BaseModel):
    class ModelInfo(BaseModel):
        name: str
        model: str

    models: list[ModelInfo]
