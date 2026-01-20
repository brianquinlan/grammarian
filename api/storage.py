from typing import Generator, cast

import models
from google.cloud import firestore

_client: firestore.Client | None = None

def _get_client() -> firestore.Client:
    global _client
    if _client is None:
        _client = firestore.Client(project='arcana-check')
    return _client

def _get_user_conversations(user_id: str) -> firestore.CollectionReference:
    return _get_client().collection("users").document(user_id).collection("conversations")

def get_conversations(user_id: str) -> Generator[models.Conversation, None, None]:
    for c in _get_user_conversations(user_id).stream():
        doc = cast(firestore.DocumentSnapshot, c)
        yield models.Conversation.model_validate(doc.to_dict())

def get_conversation(user_id: str, conversation_id: str) -> models.Conversation:
    conversations = _get_user_conversations(user_id)
    conversation_ref = conversations.document(conversation_id)
    doc = cast(firestore.DocumentSnapshot, conversation_ref.get())
    if not doc.exists:
        raise Exception('does not exist')
    
    return models.Conversation.model_validate(doc.to_dict())

def save_conversation(user_id: str, conversation: models.Conversation):
    conversation.model_dump(mode='json')
    conversations = _get_user_conversations(user_id)
    conversation_ref = conversations.document(conversation.conversation_id)
    conversation_ref.set(
        conversation.model_dump(mode='json'))