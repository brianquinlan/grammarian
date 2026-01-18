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
    agent = Agent(model, output_type=constr(min_length=10, max_length=30))

    response = await agent.run(f"""
Generate a descriptive title for a conversation that begins with this prompt:
{description}

The title should be distinct from the following existing titles:
{', '.join(existing_titles)}""")
    return response.output