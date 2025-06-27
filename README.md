<p align="center">
  <img src="https://media.canva.com/v2/image-resize/format:JPG/height:452/quality:92/uri:ifs%3A%2F%2FM%2F1b91eb55-afdb-4f01-9a0f-2aedb499f2c7/watermark:F/width:800?csig=AAAAAAAAAAAAAAAAAAAAAMJge5m3BLSlbTp_jqtS9csrKfxbCzNIbHdmdSFVY4Wo&exp=1751039687&osig=AAAAAAAAAAAAAAAAAAAAAH7pM_Lkppl_KQb9-d_u3ykpD6TYVq9pl6wPpAjQWRwo&signer=media-rpc&x-canva-quality=screen" alt="GreenBooks Banner" width="800" />
</p>

---
GreenBooks is a Flutter app that encourages users to donate, recycle, sell, or buy books while promoting environmental awareness. It calculates eco-impact metrics like trees, water, and energy saved, and uses AI to classify uploaded books by subject. Users can interact through real-time chat and earn points for their contributions.

---
## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/greenbooks.git
   cd greenbooks
---

## Features

### Authentication
- Sign up and login using email and password.
- Supports biometric login (Face ID/Fingerprint).
- “Remember Me” option for persistent login.

### AI-Based Subject Classification
- Uses **Google Gemini** to analyze and classify the content of uploaded PDFs into academic subjects.
- If Gemini fails, a **custom OCR-based fallback** (combining EasyOCR, Tesseract, and Google Vision) extracts text and infers the subject using fuzzy matching, grammar-aware filtering, and academic keyword detection.

### Chat System
- Real-time messaging with other users.
- Push notifications via Firebase Cloud Messaging.
- Red dot and badge indicators for unread messages.
- Auto-sorts users by most recent message.
- Tracks reads using a `readBy` system.

### Book Upload and Impact Tracking
- Users can upload PDF files (notes, textbooks, etc.).
- Automatically categorized by subject using AI.
- Calculates environmental metrics:
  - Trees saved
  - Energy saved
  - Water saved
  - CO₂ emissions reduced

### Points and Rewards
- Users earn points for each eco-friendly action: donating, uploading, recycling, etc.
- Points are displayed in the dashboard.
- Rewards section shows redeemable items based on points.

### Dashboard and UI
- Dashboard shows personal contribution stats, animated impact counters, and total points.
- Home screen integrates chat and activity previews.
- Consistent and clean UI throughout the app.

---

##  Initial AI Pipeline

---

###  Key Features of the System

#### 1. **Academic-Optimized OCR Pipeline**
- Multi-engine cascade: **EasyOCR → Google Vision → Tesseract**
- Domain-aware corrections using academic vocabulary
- Self-healing grammar correction using **LanguageTool**

#### 2. **Hybrid AI Classification**
- Fine-tuned **BERT** models with dynamic class weighting
- Fallback to keyword matching when model confidence is low

#### 3. **Scalable Microservices Architecture**
- Modular **FastAPI** services (OCR → Classification)
- Cloud-ready deployment:
  - Temp file cleanup
  - CORS support
  - Timeout resilience
  - Containerized with **Google Cloud Run**



## 💻 Tech Stack

<details>
<summary>🧠 Core Components</summary>

```json
{
  "OCR Engine": {
    "Primary": "EasyOCR",
    "Fallbacks": ["Google Vision API", "Tesseract"],
    "Features": [
      "Multi-engine Cascade",
      "Academic Vocabulary Enhanced"
      
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
```

</details>

<details>
<summary>🛠️ Infrastructure</summary>

```json
{
  "API Framework": "FastAPI (Async Ready)",
  "Deployment": "Google Cloud Run (Auto-scaling)",
  "CI/CD": ["Cloud Build", "Artifact Registry"],
  "Monitoring": ["Cloud Logging", "Cloud Trace"]
}
```

</details>

---

##  How to Use the AI Pipeline Fallback Model

###  Step-by-Step Guide

---

###  Part 1: Train the Classifier

1. Train the `classifier_v9.py` file.
2. Ensure your datasets are located at:

```bash
project/datasets/dataset.json
```

3. Create a folder to store model outputs:

```bash
project/models/
```

This folder will contain:
- `model.safetensors`
- `label_encoder.json`
- `tokenizer.json`
- `vocab.txt`
- etc.

✅ After this, **Part 1 is complete**.

---

### 🔹 Part 2: Setup the OCR Pipeline

1. Organize these scripts under the `project/` folder:

- Main handler: `Orchestration.py`
- OCR Engines:
  - `easy_ocr.py`
  - `google_ocr.py`
  - `tesseract_ocr.py`
- Post-processing: `domain_postprocessor.py`
- Utilities: `ocr_utils.py`

2. Make sure dataset paths are correct.
3. Test each engine locally if needed.

---

### 🔹 Part 3: Deploy the AI Model

1. Run FastAPI services locally:
   - `classification_service.py`
   - `ocr_service.py`

2. Build Docker containers:
   - `Dockerfile`
   - `Dockerfile_classification`

3. Deploy to **Google Cloud Run** using the gcloud commands below.

---

## 🗂️ Recommended Folder Structure

```bash
ai_project/
├── Dockerfile
├── Dockerfile_classification
├── requirements.txt
├── requirements_classification.txt
├── pre_cache_hf_datasets.py
├── pre_cache_languagetool.py
├── project/
│   ├── Orchestration.py
│   ├── ocr_service.py
│   ├── easy_ocr.py
│   ├── google_ocr.py
│   ├── tesseract_ocr.py
│   ├── domain_postprocessor.py
│   ├── ocr_utils.py
│   ├── classification_service.py
│   ├── classifier_v10.py
│   ├── requirements.txt
│   ├── models/
│   │   ├── model.safetensors
│   │   ├── config.json
│   │   ├── tokenizer.json
│   │   ├── vocab.txt
│   │   ├── special_tokens_map.json
│   │   └── label_encoder.json
│   ├── symspell_dicts/
│   │   ├── frequency_dictionary_en_82765.txt
│   │   └── bigram_dictionary_en_243342.txt
│   ├── languagetool_cache/
│   ├── credentials/
│   │   └── green-books-462600-dcadf7306d66.json
│   ├── datasets/
│   │   └── dataset.json
│   └── model_storage/
```

---

## ⚙️ GCloud Deployment Commands

```bash
# Configuration Variables
PROJECT_ID="your-gcp-project-id"
REGION="europe-west1"

# Docker Repos
ORCHESTRATION_DOCKER_REPO="your-orchestration-app-repo"
CLASSIFICATION_DOCKER_REPO="your-classification-app-repo"

# Service Names
ORCHESTRATION_SERVICE_NAME="your-orchestration-service"
CLASSIFICATION_SERVICE_NAME="your-classification-service"

# Image Names
ORCHESTRATION_IMAGE_NAME="your-orchestration-app"
CLASSIFICATION_IMAGE_NAME="your-classification-app"

# Ports
ORCHESTRATION_PORT=8000
CLASSIFICATION_PORT=8001

# --- Classification Service ---
gcloud builds submit   --tag "${REGION}-docker.pkg.dev/${PROJECT_ID}/${CLASSIFICATION_DOCKER_REPO}/${CLASSIFICATION_IMAGE_NAME}:latest"   --project "${PROJECT_ID}"   -f Dockerfile_classification

gcloud run deploy "${CLASSIFICATION_SERVICE_NAME}"   --image "${REGION}-docker.pkg.dev/${PROJECT_ID}/${CLASSIFICATION_DOCKER_REPO}/${CLASSIFICATION_IMAGE_NAME}:latest"   --platform managed   --region "${REGION}"   --port "${CLASSIFICATION_PORT}"   --allow-unauthenticated   --memory=8Gi   --cpu=2   --timeout=600s   --project "${PROJECT_ID}"

# --- Orchestration Service ---
gcloud builds submit   --tag "${REGION}-docker.pkg.dev/${PROJECT_ID}/${ORCHESTRATION_DOCKER_REPO}/${ORCHESTRATION_IMAGE_NAME}:latest"   --project "${PROJECT_ID}"

gcloud run deploy "${ORCHESTRATION_SERVICE_NAME}"   --image "${REGION}-docker.pkg.dev/${PROJECT_ID}/${ORCHESTRATION_DOCKER_REPO}/${ORCHESTRATION_IMAGE_NAME}:latest"   --platform managed   --region "${REGION}"   --port "${ORCHESTRATION_PORT}"   --allow-unauthenticated   --memory=8Gi   --cpu=2   --timeout=1200s   --set-env-vars CLASSIFICATION_SERVICE_URL="https://your-classification-service-YOUR_SERVICE_HASH.${REGION}.run.app/classify"   --project "${PROJECT_ID}"
```

