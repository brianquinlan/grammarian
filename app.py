from quart import request, Quart
from model_factory import get_model
import format_spell


_MODEL = get_model()

app = Quart(__name__)


@app.route("/format")
async def format():
    description = request.args.get("description")
    spell = await format_spell.format(_MODEL, description)
    print(spell)
    return spell.model_dump_json()


if __name__ == "__main__":
    app.run(debug=True)
