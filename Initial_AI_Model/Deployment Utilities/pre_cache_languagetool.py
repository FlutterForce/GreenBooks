import language_tool_python
import os
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def pre_cache_languagetool():
    cache_dir = os.getenv("LANGUAGE_TOOL_PYTHON_DIR", "/app/languagetool_cache")
    os.makedirs(cache_dir, exist_ok=True)
    language_tool_python.download_lt.DEFAULT_LANGUAGE_TOOL_DIR = cache_dir

    logging.info(f"Starting LanguageTool pre-caching to: {cache_dir}")
    try:
        logging.info("Initializing LanguageTool to cache language data...")
        tool_instance = language_tool_python.LanguageTool('en-US')
        
        _ = tool_instance.check("hello world") 
        
        logging.info("LanguageTool pre-cached successfully.")
    except Exception as e:
        logging.error(f"Failed to pre-cache LanguageTool: {e}")
        raise

if __name__ == "__main__":
    pre_cache_languagetool()
