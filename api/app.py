from quart import request, Quart
from model_factory import get_model
import format_spell
import grammarian
import fake_grammarian
import storage
import models

import uuid

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


@app.route("/grammarian", methods=["GET", "POST"])
async def _grammarian():
    conversation_id = request.args.get("conversation_id")
    if not conversation_id:
        conversation = models.Conversation(conversation_id=str(uuid.uuid4()))
    else:
        conversation = storage.get_conversation(conversation_id)
    
    if 'fake' in request.args:
        find_spells = fake_grammarian.find_spells
    else:
        find_spells = grammarian.find_spells

    description = request.args.get("description")
    if description is None:
        raise Exception('no description')
    all_messages, spells = await find_spells(_MODEL, description, conversation.all_messages)


    conversation.all_messages = all_messages
    conversation.dialog.extend([models.UserPrompt(text=description), 
                                models.AppResponse(spells=spells)])
    storage.save_conversation(conversation)

    
    response = models.ConversationResponse(conversation_id=conversation.conversation_id, spells=spells)
    return response.model_dump_json(), 200, {'Content-Type': 'application/json'}


if __name__ == "__main__":
    app.run(debug=True)
