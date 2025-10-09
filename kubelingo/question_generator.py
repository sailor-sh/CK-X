"""
Question Generator Module for Kubelingo

AI-only generation: all questions are produced via the configured provider.
Static question banks and templates have been removed.
"""

import os
from dotenv import dotenv_values
from typing import List, Dict, Any, Optional, Union
from .schema import normalize_question_dict
from .provider_adapter import generate_with_provider, ProviderError


class GenerationError(Exception):
    """Raised when question generation fails due to provider issues or invalid input."""
    pass


def _provider() -> str:
    prov = os.getenv("KUBELINGO_LLM_PROVIDER", "").strip().lower()
    if prov:
        return prov
    # Try repo-local .env (project root) next
    try:
        project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
        env_path = os.path.join(project_root, '.env')
        if os.path.exists(env_path):
            prov = (dotenv_values(env_path).get("KUBELINGO_LLM_PROVIDER", "") or "").strip().lower()
            if prov:
                return prov
    except Exception:
        pass
    # Fallback to default search
    try:
        prov = (dotenv_values().get("KUBELINGO_LLM_PROVIDER", "") or "").strip().lower()
    except Exception:
        prov = ''
    if not prov:
        raise GenerationError("No AI provider configured. Set it in the Config menu.")
    return prov


def _gen_with_provider(qtype: str, topic: Optional[str]) -> Dict[str, Any]:
    prov = _provider()
    t = topic or qtype
    try:
        item = generate_with_provider(prov, qtype, t)
    except ProviderError as e:
        raise GenerationError(str(e))
    if not isinstance(item, dict):
        raise GenerationError("Provider did not return a JSON object.")
    item.setdefault('type', qtype)
    item.setdefault('topic', t)
    return normalize_question_dict(item, t)


def gen_vocab(topic: Optional[str] = None) -> Dict[str, Any]:
    return _gen_with_provider('vocab', topic)


def gen_true_false(topic: Optional[str] = None) -> Dict[str, Any]:
    return _gen_with_provider('true_false', topic)


def gen_mcq(topic: Optional[str] = None) -> Dict[str, Any]:
    return _gen_with_provider('mcq', topic)


_GENERATORS: Dict[str, Any] = {
    'vocab': gen_vocab,
    'true_false': gen_true_false,
    'mcq': gen_mcq,
}


def gen_commands(topic: Optional[str] = None) -> Dict[str, Any]:
    return _gen_with_provider('commands', topic)


def gen_manifests(topic: Optional[str] = None) -> Dict[str, Any]:
    return _gen_with_provider('manifests', topic)


class QuestionGenerator:
    def generate_question(self, kind: str, count: int = 1, difficulty: Optional[str] = None) -> Union[Dict[str, Any], List[Dict[str, Any]]]:
        return generate_questions(kind, count, difficulty)


def generate_questions(kind: str, count: int = 1, difficulty: Optional[str] = None) -> Union[Dict[str, Any], List[Dict[str, Any]]]:
    """Generate `count` questions using the configured AI provider only.

    - If `kind` is one of: true_false, vocab, mcq, commands, manifests → use that type directly.
    - Otherwise, treat `kind` as a topic and generate manifest-type questions for that topic.
    """
    key = (kind or '').strip().lower()
    if not key:
        raise GenerationError("Missing kind/topic for generation.")

    if key in ('true_false', 'vocab', 'mcq', 'commands', 'manifests'):
        qtype = key
        topic = key
    else:
        # Resource/topic-driven generation: default to manifests
        qtype = 'manifests'
        topic = key

    prov = _provider()
    questions: List[Dict[str, Any]] = []
    seen = set()
    attempts = 0
    while len(questions) < count and attempts < count * 4:
        try:
            item = generate_with_provider(prov, qtype, topic)
            item = normalize_question_dict(item, topic)
            text = item.get('question', '')
            if text and text not in seen:
                seen.add(text)
                questions.append(item)
        except ProviderError as e:
            raise GenerationError(str(e))
        except Exception:
            pass
        finally:
            attempts += 1

    if not questions:
        raise GenerationError(f"Could not generate questions for kind '{kind}' via provider '{prov}'.")
    return questions[0] if count == 1 else questions
