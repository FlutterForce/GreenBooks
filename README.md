<p align="center">
  <img src="https://media.canva.com/v2/image-resize/format:JPG/height:452/quality:92/uri:ifs%3A%2F%2FM%2F1b91eb55-afdb-4f01-9a0f-2aedb499f2c7/watermark:F/width:800?csig=AAAAAAAAAAAAAAAAAAAAAMJge5m3BLSlbTp_jqtS9csrKfxbCzNIbHdmdSFVY4Wo&exp=1751039687&osig=AAAAAAAAAAAAAAAAAAAAAH7pM_Lkppl_KQb9-d_u3ykpD6TYVq9pl6wPpAjQWRwo&signer=media-rpc&x-canva-quality=screen" alt="GreenBooks Banner" width="800" />
</p>


## Fallback AI Pipline

<p align="center">
  <img src="https://github.com/user-attachments/assets/fcbd29a9-7635-403f-b5a2-03c14f267d95" alt="GreenBooks Banner" width="400" />
</p>

### 🚀 Key Features
- Multi-Engine OCR with Academic Focus: Combines EasyOCR (primary), Google Vision (fallback), and Tesseract (final fallback) with domain-specific optimizations for University and High School curriculum  
- Self-Healing & Context-Aware Processing: Features dynamic spell correction (preserves academic terms), grammar-aware reconstruction, and fuzzy matching (85% Levenshtein threshold) to handle low-quality scans and handwritten notes.
- Hybrid Classification System: Combines fine-tuned BERT models (including ensemble support) with keyword-based fallback for robust predictions.
- Dynamic Data Handling: Loads, balances, and preprocesses datasets from local and Hugging Face sources with class-weighting for fairness.
-  End-to-End Pipeline: Trains, evaluates, and saves models, with interactive inference for text/file inputs.


## 💻 Tech Stack
```python
{
  "OCR": ["EasyOCR", "Google Vision API", "Tesseract"],
  "NLP": ["BERT (HuggingFace)", "SymSpell", "LanguageTool"],
  "Backend": ["FastAPI", "Firebase", "Cloud Run"],
  "Data": ["IGCSE Past Papers", "BUE Lectures", "African Academic Corpus"]
}
