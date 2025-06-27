import json
import re
from typing import List, Dict, Optional
from spellchecker import SpellChecker
from rapidfuzz import fuzz
import os
from language_tool_python import LanguageTool, download_lt

download_lt.DEFAULT_LANGUAGE_TOOL_DIR = "/app/languagetool_cache"

from datasets import load_dataset as hf_load_dataset

_language_tool_instance = None

def load_dataset(filepath: str = "/app/datasets/dataset.json") -> List[Dict]:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: Dataset file not found at '{filepath}'. Please ensure it exists.")
        return []
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON format in '{filepath}'.")
        return []

def build_domain_vocabulary(dataset: List[Dict]) -> Dict[str, List[str]]:
    vocabulary = {}
    for entry in dataset:
        label = entry.get('label')
        text = entry.get('text', '')
        if label and text:
            if label not in vocabulary:
                vocabulary[label] = []
            words = [w.lower() for w in re.findall(r'\b[\w-]+\b', text) if len(w) > 2]
            vocabulary[label].extend(words)
    return vocabulary

def hf_load_and_extract_vocabulary(
    dataset_name: str,
    subset: Optional[str] = None,
    config: Optional[str] = None,
    text_columns: Optional[List[str]] = None,
    trust_remote_code: bool = False
) -> Dict[str, List[str]]:
    if text_columns is None:
        text_columns = ['text', 'question', 'answer', 'passage', 'context', 'abstract', 'description', 'solution', 'choices', 'statement', 'sentence1', 'sentence2', 'title', 'problem', 'question_stem', 'fact1', 'long_answer', 'support', 'distractor1', 'distractor2', 'distractor3', 'correct_answer']

    if subset:
        domain_key = f"{dataset_name}_{subset.replace('/', '_')}"
    elif config:
        domain_key = f"{dataset_name}_{config.replace('/', '_')}"
    else:
        domain_key = dataset_name.replace('/', '_')

    extracted_terms = []

    try:
        load_info_str = f"Loading Hugging Face dataset: {dataset_name}"
        if subset:
            load_info_str += f" (subset: {subset})"
        if config:
            load_info_str += f" (config: {config})"
        print(load_info_str)

        if subset:
            dataset = hf_load_dataset(dataset_name, subset, trust_remote_code=trust_remote_code)
        elif config:
            dataset = hf_load_dataset(dataset_name, config, trust_remote_code=trust_remote_code)
        else:
            dataset = hf_load_dataset(dataset_name, trust_remote_code=trust_remote_code)

        for split in dataset.keys():
            for item in dataset[split]:
                for col in text_columns:
                    if col in item:
                        content = item[col]
                        if isinstance(content, str):
                            words = [w.lower() for w in re.findall(r'\b[\w-]+\b', content) if len(w) > 2]
                            extracted_terms.extend(words)
                        elif isinstance(content, list):
                            for sub_item in content:
                                if isinstance(sub_item, str):
                                    words = [w.lower() for w in re.findall(r'\b[\w-]+\b', sub_item) if len(w) > 2]
                                    extracted_terms.extend(words)
                                elif isinstance(sub_item, dict) and 'text' in sub_item and isinstance(sub_item['text'], str):
                                    words = [w.lower() for w in re.findall(r'\b[\w-]+\b', sub_item['text']) if len(w) > 2]
                                    extracted_terms.extend(words)
                        elif isinstance(content, dict):
                            for key_in_dict in ['text', 'question', 'context', 'answer_text']:
                                if key_in_dict in content and isinstance(content[key_in_dict], str):
                                    words = [w.lower() for w in re.findall(r'\b[\w-]+\b', content[key_in_dict]) if len(w) > 2]
                                    extracted_terms.extend(words)
                            if dataset_name == "openbookqa" and col == "choices" and 'text' in content and isinstance(content['text'], list):
                                for choice_text in content['text']:
                                    if isinstance(choice_text, str):
                                        words = [w.lower() for w in re.findall(r'\b[\w-]+\b', choice_text) if len(w) > 2]
                                        extracted_terms.extend(words)


    except Exception as e:
        print(f"Error loading or processing Hugging Face dataset '{dataset_name}' (subset: {subset}, config: {config}): {e}")
        return {}

    return {domain_key: list(set(extracted_terms))}


def enhance_spellchecker(spell: SpellChecker, vocabulary: Dict[str, List[str]]):
    total_terms_loaded = 0
    for domain, terms in vocabulary.items():
        spell.word_frequency.load_words(terms)
        total_terms_loaded += len(terms)
    print(f"SpellChecker enhanced with {total_terms_loaded} domain terms.")

def calculate_levenshtein_accuracy(predicted_text: str, ground_truth: str) -> float:
    if not ground_truth:
        return 1.0 if not predicted_text else 0.0
    return fuzz.ratio(predicted_text, ground_truth) / 100.0

def get_domain_specific_terms(text: str, vocabulary: Dict[str, List[str]]) -> Dict[str, List[str]]:
    found_terms = {domain: [] for domain in vocabulary.keys()}
    words = re.findall(r'\b[\w-]+\b', text.lower())

    for word in words:
        for domain, terms_list in vocabulary.items():
            if word in terms_list:
                found_terms[domain].append(word)
    
    return {domain: terms for domain, terms in found_terms.items() if terms}

def calculate_domain_confidence(text: str, vocabulary: Dict[str, List[str]]) -> Dict[str, float]:
    domain_scores = {domain: 0 for domain in vocabulary.keys()}
    total_words = len(re.findall(r'\b\w+\b', text.lower()))

    if total_words == 0:
        return {domain: 0.0 for domain in vocabulary.keys()}

    for domain, terms in vocabulary.items():
        count = sum(1 for word in re.findall(r'\b\w+\b', text.lower()) if word in terms)
        domain_scores[domain] = count / total_words
    
    return domain_scores

def get_language_tool_instance():
    global _language_tool_instance
    if _language_tool_instance is None:
        try:
            print("Creating new LanguageTool instance...")
            lang_tool_path = os.getenv('LANGUAGE_TOOL_PATH', os.path.join(download_lt.DEFAULT_LANGUAGE_TOOL_DIR, 'LanguageTool'))
            if os.path.exists(os.path.join(lang_tool_path, 'LanguageTool.jar')):
                _language_tool_instance = LanguageTool('en-US', language_tool_path=lang_tool_path)
            else:
                _language_tool_instance = LanguageTool('en-US')
            print("LanguageTool instance created successfully.")
        except Exception as e:
            print(f"Error initializing LanguageTool: {e}")
            _language_tool_instance = None
    return _language_tool_instance


if __name__ == "__main__":
    print("Running ocr_utils.py example with Hugging Face datasets:")
    
    hf_datasets_to_load = [
    {"name": "math_qa", "trust_remote_code": True},
    {"name": "boolq"},
    {"name": "squad", "config": "plain_text"},
    {"name": "sciq"},
    {"name": "ai2_arc", "subset": "ARC-Challenge"},
    {"name": "cais/mmlu", "subset": "college_physics", "trust_remote_code": True},
    {"name": "cais/mmlu", "subset": "high_school_computer_science", "trust_remote_code": True},
    {"name": "cais/mmlu", "subset": "college_computer_science", "trust_remote_code": True},
    {"name": "cais/mmlu", "subset": "electrical_engineering", "trust_remote_code": True},
    {"name": "openbookqa", "config": "main"},
    {"name": "lamm-mit/MechanicsMaterials", "trust_remote_code": True},
    {"name": "GainEnergy/oilandgas-engineering-dataset"},
]
    overall_hf_vocabulary = {}
    for ds_info in hf_datasets_to_load:
        name = ds_info["name"]
        subset = ds_info.get("subset")
        config = ds_info.get("config")
        trust_remote_code = ds_info.get("trust_remote_code", False)
        
        text_cols = None
        if name == "math_qa":
            text_cols = ['problem', 'question', 'answer']
        elif name == "boolq":
            text_cols = ['question', 'passage']
        elif name == "squad":
            text_cols = ['question', 'context']
        elif name == "pubmed_qa":
            text_cols = ['question', 'long_answer', 'context']
        elif name == "sciq":
            text_cols = ['question', 'support', 'distractor1', 'distractor2', 'distractor3', 'correct_answer']
        elif name == "ai2_arc":
            text_cols = ['question', 'choices']
        elif name == "openbookqa":
            text_cols = ['question_stem', 'choices', 'fact1']
        elif name == "lamm-mit/MechanicsMaterials":
            text_cols = ['text']
        elif name == "GainEnergy/oilandgas-engineering-dataset":
            text_cols = ['text']

        domain_vocab = hf_load_and_extract_vocabulary(
            name,
            subset=subset,
            config=config,
            text_columns=text_cols,
            trust_remote_code=trust_remote_code
        )
        overall_hf_vocabulary.update(domain_vocab)
    
    print("\nOverall Hugging Face Vocabulary (first few terms from each domain):")
    for domain, terms in list(overall_hf_vocabulary.items())[:5]:
        print(f"  {domain}: {terms[:10]}...")
    if len(overall_hf_vocabulary) > 5:
        print(f"  ...and {len(overall_hf_vocabulary)-5} more domains.")

    spell_checker = SpellChecker()
    enhance_spellchecker(spell_checker, overall_hf_vocabulary)

    test_text_hf = "The oil and gass industry uses hydraulic fracturing to extract gas from shale."
    print(f"\nTest Text for HF enhanced SpellChecker: '{test_text_hf}'")
    corrected_hf = spell_checker.correction("gass")
    print(f"Correction for 'gass': {corrected_hf}")
