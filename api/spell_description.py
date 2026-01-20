import argparse

import model_factory
import models
from pydantic_ai import Agent
from pydantic_ai.models import Model

_PROMPT = '''Imagine a new dungeons and dragons 5e spell called
"{name}".
'''

_MULTI_PROMPT = _PROMPT + '''
Generate {count} different interpretations of the spell in terms of school,
level, and effects. The name of the spell must always be "{name}".
'''

def generate(model: Model, name: str, count: int = 1) -> list[models.Spell]:
    if count == 1:
        prompt = _PROMPT.format(name=name)
    else:
        prompt = _MULTI_PROMPT.format(count=count,name=name)

    agent = Agent(model, output_type=list[models.Spell])
    response = agent.run_sync(prompt)

    return response.output


def main():
    model = model_factory.get_model()

    parser = argparse.ArgumentParser(description="What the program does")
    parser.add_argument("-n", "--name")
    parser.add_argument("-c", "--count", type=int)
    args = parser.parse_args()

    for variation in generate(model, args.name, args.count):
        print(variation.model_dump())


if __name__ == '__main__':
    main()