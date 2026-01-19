import argparse
import asyncio
import dataclasses
import string
import sys
from typing import Generator, Tuple

from pydantic_ai import Agent, ModelMessage, RunContext, Tool
from pydantic_ai.models import Model


from model_factory import get_model

import models
async def find_spells(
    model: Model, description: str,
    model_messages : list[ModelMessage] | None = [],
) -> Tuple[list[ModelMessage], list[models.RingOfTheGrammarianSpell]]:
    await asyncio.sleep(2)
    firefall = models.RingOfTheGrammarianSpell(
        original_spell_name="Fireball",
        grammarian_spell=models.Spell(
            name="Firefall",
            school=models.School.EVOCATION,
            level=models.Level.THIRD,
            casting_time="1 action",
            range="150 feet",
            components="V, S, M (a piece of charcoal)",
            duration="Concentration, up to 1 minute",
            description="Fire rains down in a 40-foot-radius, 40-foot-high cylinder centered on a point within range. When a creature enters the area for the first time on a turn or starts its turn there, it must make a Dexterity saving throw. It takes 3d6 fire damage on a failed save, or half as much damage on a successful one. At higher levels: When you cast this spell using a spell slot of 4th level or higher, the damage increases by 1d6 for each slot level above 3rd."
        )
    )

    bliss = models.RingOfTheGrammarianSpell(
        original_spell_name="Bless",
        grammarian_spell=models.Spell(
            name="Bliss",
            school=models.School.ENCHANTMENT,
            level=models.Level.SECOND,
            casting_time="1 action",
            range="30 feet",
            components="V, S",
            duration="Concentration, up to 1 minute",
            description="You fill a creature's mind with overwhelming euphoria. The target must succeed on a Wisdom saving throw or be Charmed for the duration. While Charmed, the creature's speed is 0 and it is Incapacitated as it revels in the feeling. The spell ends if the target takes damage. At higher levels: When you cast this spell using a spell slot of 3rd level or higher, you can target one additional creature for each slot level above 2nd. The creatures must be within 30 feet of each other when you target them."
        )
    )

    mage_wand = models.RingOfTheGrammarianSpell(
        original_spell_name="Mage Hand",
        grammarian_spell=models.Spell(
            name="Mage Wand",
            school=models.School.CONJURATION,
            level=models.Level.CANTRIP,
            casting_time="1 action",
            range="Self",
            components="V, S",
            duration="1 hour",
            description="You conjure a spectral wand in your hand. While holding this wand, you can use it to cast any cantrip you know that has a range of at least 5 feet. When you do so, the cantrip's range is doubled. At higher levels: The wand's power increases when you reach higher levels. At 5th level, you gain a +1 bonus to spell attack rolls with cantrips cast through the wand. This bonus increases to +2 at 11th level and +3 at 17th level."
        )
    )

    grammarian_spells = [firefall, bliss, mage_wand]
    return [], grammarian_spells