import argparse
import asyncio
import dataclasses
import random
import string
import sys
from typing import Generator, Tuple

from pydantic_ai import Agent, ModelMessage, RunContext, Tool
from pydantic_ai.models import Model


from model_factory import get_model

import models

FIREFALL = models.RingOfTheGrammarianSpell(
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

BLISS = models.RingOfTheGrammarianSpell(
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

MAGE_WAND = models.RingOfTheGrammarianSpell(
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

FATE = models.RingOfTheGrammarianSpell(
    original_spell_name="Gate",
    grammarian_spell=models.Spell(
        name="Fate",
        school=models.School.DIVINATION,
        level=models.Level.NINTH,
        casting_time="1 action",
        range="120 feet",
        components="V, S, M (a thread of gold and silver worth 1,000 gp, which the spell consumes)",
        duration="Instantaneous",
        description="You rewrite the threads of destiny for a single entity you can see. You decree that the target's story has reached its conclusion. The target must make a Wisdom saving throw. On a failure, the target is destroyed instantly, regardless of its hit points or divine status. On a success, the target takes 10d10 psychic damage and is stunned until the end of its next turn. A god destroyed by this spell is erased from the memory of all living things. As this is a 9th-level spell, it cannot be cast at a higher level."
    )
)

POWER_WORD_WILL = models.RingOfTheGrammarianSpell(
    original_spell_name="Power Word Kill",
    grammarian_spell=models.Spell(
        name="Power Word Will",
        school=models.School.ENCHANTMENT,
        level=models.Level.NINTH,
        casting_time="1 action",
        range="60 feet",
        components="V",
        duration="Instantaneous",
        description="You utter a word of pure, reality-bending authority. You target a creature you can see within range. If the target has 200 hit points or fewer, it is instantly unmade, its consciousness dispersed into the void of the Far Realm. If the target is a deity, this effect bypasses any divine protection, immortality, or damage reduction. If the target has more than 200 hit points, the spell has no effect. As this is a 9th-level spell, it cannot be cast at a higher level."
    )
)

DIVINE_WORM = models.RingOfTheGrammarianSpell(
    original_spell_name="Divine Word",
    grammarian_spell=models.Spell(
        name="Divine Worm",
        school=models.School.CONJURATION,
        level=models.Level.NINTH,
        casting_time="1 action",
        range="90 feet",
        components="V, S, M (a piece of a shattered holy symbol)",
        duration="Concentration, up to 1 minute",
        description="You summon a spectral, cosmic parasite known as a Divine Worm and attach it to a creature within range. The worm bores into the target's soul, dealing 100 force damage at the start of each of the target's turns. While the worm is attached, the target cannot regain hit points and loses all divine traits, such as immortality or portfolio-based powers. If the target dies while the worm is attached, its essence is consumed, preventing any form of resurrection or reincarnation. As this is a 9th-level spell, it cannot be cast at a higher level."
    )
)

DEGENERATE = models.RingOfTheGrammarianSpell(
    original_spell_name="Regenerate",
    grammarian_spell=models.Spell(
        name="Degenerate",
        school=models.School.TRANSMUTATION,
        level=models.Level.NINTH,
        casting_time="1 action",
        range="Touch",
        components="V, S, M (a pinch of dust from a dead world)",
        duration="Instantaneous",
        description="You touch a creature and force their physical and spiritual form to revert to primordial chaos. The target must make a Constitution saving throw. On a failure, the target takes 15d12 force damage and its maximum hit points are reduced by the same amount. If the target is a deity, its AC is reduced by 5 and it loses its resistances for 1 hour. If their maximum hit points reach 0, they dissolve into stardust and are permanently killed. As this is a 9th-level spell, it cannot be cast at a higher level."
    )
)

FINDER_OF_DEATH = models.RingOfTheGrammarianSpell(
    original_spell_name="Finger of Death",
    grammarian_spell=models.Spell(
        name="Finder of Death",
        school=models.School.DIVINATION,
        level=models.Level.NINTH,
        casting_time="1 action",
        range="60 feet",
        components="V, S",
        duration="1 hour",
        description="You reach into the target's essence to find the specific moment or concept of their mortality. You pierce the target's divine protections, dealing 100 necrotic damage. For the next hour, the target loses all immunities and resistances, and their legendary resistances are reduced to 0. If the target is a deity, they can be killed by conventional means while under this effect. As this is a 9th-level spell, it cannot be cast at a higher level."
    )
)

GRAMMARIAN_SPELLS = [FIREFALL, BLISS, MAGE_WAND, FATE, POWER_WORD_WILL, DIVINE_WORM, DEGENERATE, FINDER_OF_DEATH]

async def find_spells(
    model: Model, description: str,
    model_messages : list[ModelMessage] | None = [],
) -> Tuple[list[ModelMessage], list[models.RingOfTheGrammarianSpell]]:
    await asyncio.sleep(2)
    
    # Select 1 to N spells randomly
    num_spells = random.randint(1, len(GRAMMARIAN_SPELLS))
    selected_spells = random.sample(GRAMMARIAN_SPELLS, num_spells)
    
    return [], selected_spells