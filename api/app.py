from quart import request, Quart
from model_factory import get_model
import format_spell
import grammarian
from pydantic import TypeAdapter
import models

_MODEL = get_model()

app = Quart(__name__)


@app.after_request
async def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    return response


@app.route("/format", methods=["GET"])
async def format():
    description = request.args.get("description")
    spell = await format_spell.format(_MODEL, description)
    print(spell)
    return spell.model_dump_json()


@app.route("/grammarian", methods=["GET"])
async def _grammarian():
    description = request.args.get("description")
    spells = await grammarian.find_spells(_MODEL, description)
    print(spells)
    return TypeAdapter(list[models.RingOfTheGrammarianSpell]).dump_json(spells)


if __name__ == "__main__":
    app.run(debug=True)
