import argparse
from typing import cast

import fake_grammarian
import fake_titler
import firebase_admin
import grammarian
import models
import storage
import titler
from firebase_admin import auth
from model_factory import get_model, AVAILABLE_MODELS
from quart import Quart, abort, request
from pydantic_ai.models import Model

# Initialize Firebase Admin
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app()


app = Quart(__name__)


@app.after_request
async def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET, PUT, POST, OPTIONS"
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


@app.route("/models", methods=["GET"])
async def list_models():
    models_list = [
        models.ModelInfo(name=name, model=model)
        for name, model in AVAILABLE_MODELS.items()
    ]
    return (
        models.ListModelsResponse(models=models_list).model_dump_json(),
        200,
        {"Content-Type": "application/json"},
    )


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
async def get_conversation(conversation_id: str):
    user_id = get_user_id()
    conversation = storage.get_conversation(user_id, conversation_id)
    return conversation.model_dump_json(), 200, {"Content-Type": "application/json"}


async def _respond(user_id: str, conversation: models.Conversation, description: str):
    if app.config.get("NO_LLM"):
        all_messages, sage_answer = await fake_grammarian.find_spells(
            description,
            conversation.all_messages,
            delay=app.config.get("FAKE_GRAMMARIAN_SAGE_DELAY", 2.0),
        )
    else:
        model = get_model(conversation.model)
        all_messages, sage_answer = await grammarian.find_spells(
            model, description, conversation.all_messages
        )
    conversation.all_messages = all_messages
    conversation.dialog.extend(
        [
            models.UserPrompt(text=description),
            models.AppResponse(sage_answer=sage_answer),
        ]
    )
    storage.save_conversation(user_id, conversation)

    response = models.PromptResponse(
        conversation_id=conversation.conversation_id, sage_answer=sage_answer
    )
    return response.model_dump_json(), 200, {"Content-Type": "application/json"}


@app.route("/conversation/<conversation_id>", methods=["PUT"])
async def create_conversation(conversation_id: str):
    user_id = get_user_id()

    data = await request.get_json()

    conversation_id = data.get("conversation_id")
    if not conversation_id:
        abort(400, description="conversation_id is required")

    description = data.get("description")
    if not description:
        abort(400, description="description is required")

    model_name = data.get("model")
    if not model_name:
        abort(400, description="model is required")


    if app.config.get("NO_LLM"):
        title_conversation = fake_titler.title_conversation
    else:
        title_conversation = titler.title_conversation

    existing_titles = [c.name for c in storage.get_conversations(user_id)]
    title = await title_conversation(
        description=description,
        existing_titles=existing_titles,
    )
    conversation = models.Conversation(
        conversation_id=conversation_id, name=title, model=model_name
    )
    return await _respond(user_id, conversation, description)


@app.route("/conversation/<conversation_id>", methods=["POST"])
async def update_conversation(conversation_id: str):
    user_id = get_user_id()

    data = await request.get_json()
    description = data.get("description")
    if not description:
        abort(400, description="description is required")

    conversation = storage.get_conversation(user_id, conversation_id)
    return await _respond(user_id, conversation, description)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-llm", action="store_true", help="Use fake LLM")
    parser.add_argument(
        "--fake-grammarian-sage-delay",
        type=float,
        default=2.0,
        help="Delay in seconds for fake grammarian",
    )
    args = parser.parse_args()

    app.config["NO_LLM"] = args.no_llm
    app.config["FAKE_GRAMMARIAN_SAGE_DELAY"] = args.fake_grammarian_sage_delay
    app.run(debug=True)
