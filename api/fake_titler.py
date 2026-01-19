import argparse
import asyncio
import dataclasses
import string
import sys
from typing import Generator, Tuple

from pydantic import constr
from pydantic_ai import Agent, ModelMessage, RunContext, Tool
from pydantic_ai.models import Model


from model_factory import get_model

import models

async def title_conversation(model: Model, description: str, existing_titles: list[str]) -> str:
    return description[:30]