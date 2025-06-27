<p align="center">
  <img src="https://github.com/user-attachments/assets/3e56e4ef-1f35-4688-9535-5d626e26d964" alt="GreenBooks Logo" />
</p>

## Fallback AI Pipline

<p align="center">
  <img src="https://github.com/user-attachments/assets/fcbd29a9-7635-403f-b5a2-03c14f267d95" alt="GreenBooks Banner" width="400" />
</p>

### 🚀 Key Features
- **Multi-engine OCR pipeline** (EasyOCR → Google Vision fallback 1 → Tesseract fallback 2)
- **Academic-specific NLP** (BERT fine-tuned on 1000+ academic samples)
- **Self-healing text processing** with domain-aware correction


## 💻 Tech Stack
```python
{
  "OCR": ["EasyOCR", "Google Vision API", "Tesseract"],
  "NLP": ["BERT (HuggingFace)", "SymSpell", "LanguageTool"],
  "Backend": ["FastAPI", "Firebase", "Cloud Run"],
  "Data": ["IGCSE Past Papers", "BUE Lectures", "African Academic Corpus"]
}
