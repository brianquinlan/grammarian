import enum
from typing import TextIO

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
    UNKNOWN = "Unknown"
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
    duration: str
    description: str

    def foo(self, f: TextIO):
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
