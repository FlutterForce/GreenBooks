import re
import json
from typing import Dict, List
from rapidfuzz import fuzz

class DomainPostProcessor:
    def __init__(self, dataset_path: str = "/app/datasets/dataset.json"):
        self.domain_patterns = self._load_domain_patterns(dataset_path)
    
    def _load_domain_patterns(self, dataset_path: str) -> Dict[str, List[str]]:
        from collections import defaultdict
        
        try:
            with open(dataset_path, 'r', encoding='utf-8') as f:
                dataset = json.load(f)
        except FileNotFoundError:
            print(f"Error: Dataset file not found at '{dataset_path}'. Cannot load domain patterns.")
            return defaultdict(list)
        except json.JSONDecodeError:
            print(f"Error: Invalid JSON format in '{dataset_path}'. Cannot load domain patterns.")
            return defaultdict(list)
            
        patterns = defaultdict(list)
        for entry in dataset:
            label = entry.get('label')
            text = entry.get('text', '')
            if label and text:
                formula_matches = re.findall(r'([A-Z][a-z]?\d*)+|([A-Z][a-z]?\d*[\+\-→=].+)', text)
                
                for match_tuple in formula_matches:
                    clean_match = next((m for m in match_tuple if m), None)
                    
                    if clean_match:
                        clean_match = clean_match.strip()
                        
                        if len(clean_match) > 1 and clean_match not in patterns[label]:
                            patterns[label].append(clean_match)
        return patterns
    
    def correct_domain_specific(self, text: str, domain: str) -> str:
        if domain not in self.domain_patterns:
            return text
            
        words_and_delimiters = re.findall(r'(\w+)([^\w\s]*|\s+)', text)
        
        corrected_parts = []
        for word, delimiter in words_and_delimiters:
            replaced = False
            for pattern in self.domain_patterns[domain]:
                if fuzz.ratio(word, pattern) > 85:
                    corrected_parts.append(pattern + delimiter)
                    replaced = True
                    break
            if not replaced:
                corrected_parts.append(word + delimiter)
                
        return ''.join(corrected_parts).strip()
