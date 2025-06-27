<p align="center">
  <img src="https://media.canva.com/v2/image-resize/format:JPG/height:452/quality:92/uri:ifs%3A%2F%2FM%2F1b91eb55-afdb-4f01-9a0f-2aedb499f2c7/watermark:F/width:800?csig=AAAAAAAAAAAAAAAAAAAAAMJge5m3BLSlbTp_jqtS9csrKfxbCzNIbHdmdSFVY4Wo&exp=1751039687&osig=AAAAAAAAAAAAAAAAAAAAAH7pM_Lkppl_KQb9-d_u3ykpD6TYVq9pl6wPpAjQWRwo&signer=media-rpc&x-canva-quality=screen" 
       alt="GreenBooks Banner" width="800" />
</p>

---

## 📌 Fallback AI Pipeline

<p align="center">
  <img src="https://github.com/user-attachments/assets/fcbd29a9-7635-403f-b5a2-03c14f267d95" 
       alt="Pipeline Diagram" width="400" />
</p>

---

### 🚀 Key Features of the System

#### 1. **Academic-Optimized OCR Pipeline**
- Multi-engine cascade: **EasyOCR → Google Vision → Tesseract**
- Domain-aware corrections using academic vocabulary
- Self-healing grammar correction using **LanguageTool**

#### 2. **Hybrid AI Classification**
- Fine-tuned **BERT** models with dynamic class weighting
- Fallback to keyword matching when model confidence is low

#### 3. **Scalable Microservices Architecture**
- Modular **FastAPI** services (OCR → Classification)
- Cloud-ready deployment with:
  - Temp file cleanup
  - CORS support
  - 10-minute timeout resilience
  - Containerized using **Google Cloud Run**

---

## 💻 Tech Stack

<details>
<summary>🧠 Core Components</summary>

```json
{
  "OCR Engine": {
    "Primary": "EasyOCR (CNN-LSTM Hybrid)",
    "Fallbacks": ["Google Vision API (Document AI)", "Tesseract 5 (LSTM)"],
    "Features": [
      "Multi-engine Cascade",
      "Academic Vocabulary Injection",
      "90%+ Accuracy on STEM Content"
    ]
  },
  "NLP Pipeline": {
    "Classification": "BERT-base (HuggingFace Transformers)",
    "Text Processing": [
      "SymSpell (Domain-Enhanced Spellcheck)",
      "LanguageTool (Grammar-Aware Reconstruction)",
      "NLTK (Lemmatization/Tokenization)"
    ],
    "Ensemble": ["SciBERT", "RoBERTa (Weighted Voting)"]
  }
}
