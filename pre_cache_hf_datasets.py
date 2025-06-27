import os
from datasets import load_dataset
import logging
import time
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

os.environ['HF_DATASETS_OFFLINE'] = '0'

hf_datasets_to_load = [
    {"name": "math_qa", "trust_remote_code": True, "splits": ["train", "validation", "test"]},
    {"name": "boolq", "splits": ["train", "validation"]},
    {"name": "squad", "config": "plain_text", "splits": ["train", "validation"]},
    {"name": "pubmed_qa", "subset": "pqa_labeled", "splits": ["train"]},
    {"name": "sciq", "splits": ["train", "validation", "test"]},
    {"name": "ai2_arc", "subset": "ARC-Challenge", "splits": ["train", "validation", "test"]},
    {"name": "cais/mmlu", "subset": "college_physics", "trust_remote_code": True, "splits": ["test", "validation", "dev"]},
    {"name": "cais/mmlu", "subset": "high_school_computer_science", "trust_remote_code": True, "splits": ["test", "validation", "dev"]},
    {"name": "cais/mmlu", "subset": "college_computer_science", "trust_remote_code": True, "splits": ["test", "validation", "dev"]},
    {"name": "cais/mmlu", "subset": "electrical_engineering", "trust_remote_code": True, "splits": ["test", "validation", "dev"]},
    {"name": "openbookqa", "config": "main", "splits": ["train", "validation", "test"]},
    {"name": "lamm-mit/MechanicsMaterials", "trust_remote_code": True, "splits": ["train"]},
    {"name": "GainEnergy/oilandgas-engineering-dataset", "splits": ["train"]},
]

@retry(
    stop=stop_after_attempt(5),
    wait=wait_exponential(multiplier=1, min=10, max=60),
    retry=retry_if_exception_type(Exception),
    reraise=True
)
def load_and_cache_hf_dataset(name, subset=None, config=None, trust_remote_code=False, splits_to_load=None):
    if splits_to_load is None:
        splits_to_load = ['train']

    loaded_at_least_one_split = False
    for split in splits_to_load:
        try:
            logging.info(f"    Attempting to load split: '{split}' for {name}" + (f" (subset: {subset})" if subset else "") + (f" (config: {config})" if config else ""))
            if subset:
                load_dataset(name, subset, split=split, trust_remote_code=trust_remote_code)
            elif config:
                load_dataset(name, config, split=split, trust_remote_code=trust_remote_code)
            else:
                load_dataset(name, split=split, trust_remote_code=trust_remote_code)
            logging.info(f"    Successfully loaded split: '{split}'")
            loaded_at_least_one_split = True
        except Exception as e:
            if "Unknown split" in str(e):
                logging.warning(f"    Split '{split}' not found for {name}. Trying next available split. Error: {e}")
            else:
                raise

    if not loaded_at_least_one_split:
        raise Exception(f"No splits could be loaded for dataset {name}")


print("--- Starting Hugging Face Dataset Pre-caching ---")

for ds_info in hf_datasets_to_load:
    name = ds_info["name"]
    subset = ds_info.get("subset")
    config = ds_info.get("config")
    trust_remote_code = ds_info.get("trust_remote_code", False)
    splits = ds_info.get("splits")

    try:
        logging.info(f"Attempting to load and cache dataset: {name}" + (f" (subset: {subset})" if subset else "") + (f" (config: {config})" if config else ""))
        load_and_cache_hf_dataset(name, subset=subset, config=config, trust_remote_code=trust_remote_code, splits_to_load=splits)
        logging.info(f"Successfully loaded and cached: {name}" + (f" (subset: {subset})" if subset else "") + (f" (config: {config})" if config else ""))
    except Exception as e:
        logging.error(f"Failed to load and cache dataset {name}" + (f" (subset: {subset})" if subset else "") + f" after multiple retries: {e}")

    time.sleep(5)

print("--- Finished Hugging Face Dataset Pre-caching ---")

os.environ['HF_DATASETS_OFFLINE'] = '1'
