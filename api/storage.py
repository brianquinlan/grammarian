from typing import Generator, cast

import models
from google.cloud import firestore

_client: firestore.Client | None = None

def _get_client() -> firestore.Client:
    global _client
    if _client is None:
        _client = firestore.Client(project='arcana-check')
    return _client

def get_user_settings(user_id: str) -> models.UserSettings:
    settings_ref = _get_client().collection("users").document(user_id)
    doc = cast(firestore.DocumentSnapshot, settings_ref.get())
    if not doc.exists:
        raise Exception('does not exist')
    return models.UserSettings.model_validate(doc.to_dict())


def save_user_settings(user_id: str, settings: models.UserSettings):
    settings_ref = _get_client().collection("users").document(user_id)
    settings_ref.set(settings.model_dump(mode='json'))


def get_conversations(user_id: str) -> Generator[models.Conversation, None, None]:
    for c in _get_client().collection("conversations").where("owner_id", "==", user_id).stream():
        doc = cast(firestore.DocumentSnapshot, c)
        yield models.Conversation.model_validate(doc.to_dict())

def get_conversation(conversation_id: str) -> models.Conversation:
    conversation_ref = _get_client().collection("conversations").document(conversation_id)
    doc = cast(firestore.DocumentSnapshot, conversation_ref.get())
    if not doc.exists:
        raise Exception('does not exist')
    
    return models.Conversation.model_validate(doc.to_dict())

def save_conversation(conversation: models.Conversation):
    conversation_ref = _get_client().collection("conversations").document(conversation.conversation_id)
    conversation_ref.set(
        conversation.model_dump(mode='json'))