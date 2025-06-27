from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
from transformers import BertTokenizer, BertForSequenceClassification, BertConfig
from safetensors import safe_open
import torch
import numpy as np
import json
import os
from typing import (
    Dict,
    Union
)
import io

app = FastAPI()

MODEL_DIR = "/app/models"
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model = None
tokenizer = None
id2label = None
label2id = None

def load_model_components():
    global model, tokenizer, id2label, label2id

    try:
        if not os.path.exists(MODEL_DIR):
            raise FileNotFoundError(f"Model directory '{MODEL_DIR}' not found. Please ensure your model files are placed in this directory.")

        print(f"Loading components from {MODEL_DIR}...")

        tokenizer = BertTokenizer.from_pretrained(MODEL_DIR)
        print("✅ BertTokenizer loaded.")

        label_encoder_path = os.path.join(MODEL_DIR, "label_encoder.json")
        if not os.path.exists(label_encoder_path):
            raise FileNotFoundError(f"Label encoder file '{label_encoder_path}' not found.")
        
        with open(label_encoder_path, 'r', encoding='utf-8') as f:
            class_labels = json.load(f)
        
        id2label = {i: label for i, label in enumerate(class_labels)}
        label2id = {label: i for i, label in enumerate(class_labels)}
        print(f"✅ Label mappings loaded: {id2label}")

        config = BertConfig.from_pretrained(MODEL_DIR)
        config.num_labels = len(class_labels)
        config.id2label = id2label
        config.label2id = label2id
        print("✅ Model configuration loaded.")

        model = BertForSequenceClassification.from_pretrained(
            MODEL_DIR,
            config=config
        )
        model.to(DEVICE)
        model.eval()
        print("✅ Fine-tuned BERT model loaded.")

    except Exception as e:
        raise RuntimeError(f"Model loading failed: {str(e)}")

@app.on_event("startup")
async def startup_event():
    global model, tokenizer, id2label, label2id
    try:
        load_model_components()
        print("✅ All model components loaded successfully!")
    except Exception as e:
        print(f"❌ Fatal error during model loading at startup: {str(e)}")
        raise RuntimeError(f"Service startup failed due to model loading error: {str(e)}")

class PredictionResponse(BaseModel):
    predicted_class: str

@app.post("/classify", response_model=PredictionResponse)
async def classify_input(
    text: Union[str, None] = None,
    file: UploadFile = File(None)
):
    input_text = ""
    try:
        if not text and not file:
            raise HTTPException(400, "Either 'text' or 'file' must be provided.")

        if text:
            input_text = text.strip()
        elif file:
            if file.content_type != "text/plain":
                raise HTTPException(400, "Only text files (.txt) are accepted for classification.")

            contents = await file.read()
            input_text = contents.decode("utf-8").strip()

        if not input_text:
            raise HTTPException(400, "Input text cannot be empty or consist only of whitespace.")
        
        if model is None or tokenizer is None or id2label is None:
            raise HTTPException(500, "Classification service not initialized. Models are not loaded.")

        inputs = tokenizer(
            input_text,
            padding=True,
            truncation=True,
            max_length=512,
            return_tensors="pt"
        ).to(DEVICE)

        with torch.no_grad():
            outputs = model(**inputs)

        logits = outputs.logits
        probabilities = torch.softmax(logits, dim=1).cpu().numpy()[0]
        predicted_class_id = np.argmax(probabilities)

        return {
            "predicted_class": id2label[predicted_class_id]
        }

    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Classification error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
