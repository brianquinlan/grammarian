from quart import request, Quart, abort
import argparse
from model_factory import get_model
import grammarian
import fake_grammarian
import fake_titler
import storage
import models
import titler
import uuid
import firebase_admin
from firebase_admin import auth

# Initialize Firebase Admin
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app()

_MODEL = get_model()

app = Quart(__name__)

@app.after_request
async def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return response

def get_user_id():
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        print(f"Missing or invalid auth header: {auth_header}")
        abort(401, description="Missing or invalid Authorization header")
    
    token = auth_header.split("Bearer ")[1]
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token["uid"]
    except Exception as e:
        print(f"Auth error: {e}")
        abort(401, description="Invalid token")


@app.route("/conversations", methods=["GET"])
async def conversations():
    user_id = get_user_id()
    summaries = [
        models.ConversationSummary(
            conversation_id=c.conversation_id, name=c.name, created_on=c.created_on
        )
        for c in storage.get_conversations(user_id)
    ]

    summaries.sort(key=lambda c: c.created_on)
    return (
        models.ListConversationsResponse(conversations=summaries).model_dump_json(),
        200,
        {"Content-Type": "application/json"},
    )


@app.route("/conversation/<conversation_id>", methods=["GET"])
async def conversation(conversation_id: str):
    user_id = get_user_id()
    conversation = storage.get_conversation(user_id, conversation_id)
    return conversation.model_dump_json(), 200, {"Content-Type": "application/json"}


@app.route("/prompt", methods=["GET", "POST"])
async def prompt():
    user_id = get_user_id()
    conversation_id = request.args.get("conversation_id")
    description = request.args.get("description")

    if app.config.get("NO_LLM"):
        find_spells = fake_grammarian.find_spells
        title_conversation = fake_titler.title_conversation
    else:
        find_spells = grammarian.find_spells
        title_conversation = titler.title_conversation

    if description is None:
        raise Exception("no description")
    if not conversation_id:
        existing_titles = [c.name for c in storage.get_conversations(user_id)]
        title = await title_conversation(
            _MODEL,
            description=description,
            existing_titles=existing_titles,
        )
        conversation = models.Conversation(conversation_id=str(uuid.uuid4()), name=title)
    else:
        conversation = storage.get_conversation(user_id, conversation_id)



    all_messages, spells = await find_spells(
        _MODEL, description, conversation.all_messages
    )
    conversation.all_messages = all_messages
    conversation.dialog.extend(
        [models.UserPrompt(text=description), models.AppResponse(spells=spells)]
    )
    storage.save_conversation(user_id, conversation)

    response = models.PromptResponse(
        conversation_id=conversation.conversation_id, spells=spells
    )
    return response.model_dump_json(), 200, {"Content-Type": "application/json"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-llm", action="store_true", help="Use fake LLM")
    args = parser.parse_args()
    
    app.config["NO_LLM"] = args.no_llm
    app.run(debug=True)