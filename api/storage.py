from typing import cast
from google.cloud import firestore
import models

_client: firestore.Client | None = None
_conversations: firestore.CollectionReference | None = None

def _get_client() -> firestore.Client:
    global _client
    if _client is None:
        _client = firestore.Client()
    return _client


def _get_conversations():
    global _conversations
    if _conversations is None:
        _conversations = _get_client().collection("conversations")
    return _conversations

def get_conversation(conversation_id: str) -> models.Conversation:
    conversations = _get_conversations()
    conversation_ref = conversations.document(conversation_id)
    doc = cast(firestore.DocumentSnapshot, conversation_ref.get())
    if not doc.exists:
        raise Exception('does not exist')
    
    return models.Conversation.model_validate(doc.to_dict())

def save_conversation(conversation: models.Conversation):
    conversation.model_dump(mode='json')
    conversations = _get_conversations()
    conversation_ref = conversations.document(conversation.conversation_id)
    conversation_ref.set(
        conversation.model_dump(mode='json'))
