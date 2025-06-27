from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
import os
import shutil
import tempfile
import requests
from typing import List, Dict, Union,Optional
from fastapi.middleware.cors import CORSMiddleware
import io
import sys
print("Starting Orchestration service...")
print(f"Python version: {sys.version}")
print(f"Environment variables: {dict(os.environ)}")


try:
    from ocr_service import process_pdf_with_fallback
except ImportError:
    raise RuntimeError(
        "Could not import 'process_pdf_with_fallback' from 'ocr_service.py'. "
        "Please ensure 'ocr_service.py' is in the same directory or its path is correct, "
        "and that it has been modified as provided in the previous turn."
    )

app = FastAPI(
    title="Document Processing Orchestration Service",
    description="API for OCR and text classification of PDF documents.",
    version="0.1.0",
    openapi_url="/openapi.json"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

CLASSIFICATION_SERVICE_URL = os.getenv("CLASSIFICATION_SERVICE_URL", "https://YOUR_CLASSIFICATION_SERVICE_CLOUD_RUN_URL/classify")

class OCRPageResult(BaseModel):
    page_number: int
    raw_text: str
    corrected_text: str
    engine_used: str
    grammar_issues_count: int


class OCRResponse(BaseModel):
    pages: List[OCRPageResult]
    total_extracted_text: str


class ClassificationResponse(BaseModel):
    predicted_class: str
    confidence: Optional[float] = None
    class_probabilities: Optional[Dict[str, float]] = None


class OCRAndClassificationResponse(BaseModel):
    ocr_results: OCRResponse
    classification_result: ClassificationResponse


@app.post("/ocr", response_model=OCRResponse, summary="Process Document Only OCR")
async def process_document_only_ocr(
    file: UploadFile = File(..., media_type="application/pdf")
):
    if file.content_type != "application/pdf":
        raise HTTPException(
            status_code=400, detail="Only PDF files (.pdf) are accepted."
        )

    temp_dir = tempfile.mkdtemp()
    temp_pdf_path = os.path.join(temp_dir, file.filename)

    try:
        with open(temp_pdf_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        temp_output_dir = os.path.join(temp_dir, "output")
        os.makedirs(temp_output_dir, exist_ok=True)

        ocr_page_results = process_pdf_with_fallback(temp_pdf_path, temp_output_dir)

        total_extracted_text = "\n".join(
            [page["corrected_text"] for page in ocr_page_results]
        )

        formatted_ocr_page_results = [
            OCRPageResult(**res) for res in ocr_page_results
        ]

        return OCRResponse(
            pages=formatted_ocr_page_results,
            total_extracted_text=total_extracted_text,
        )

    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=f"File error: {e}")
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"An unexpected error occurred during OCR: {e}"
        )
    finally:
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)


@app.post(
    "/ocr_and_classify",
    response_model=OCRAndClassificationResponse,
    summary="Process Document And Classify",
    description="Endpoint to perform OCR and then classify the extracted text.",
)
async def process_document_and_classify(
    file: UploadFile = File(..., media_type="application/pdf")
):
    if file.content_type != "application/pdf":
        raise HTTPException(
            status_code=400, detail="Only PDF files (.pdf) are accepted."
        )

    temp_dir = tempfile.mkdtemp()
    temp_pdf_path = os.path.join(temp_dir, file.filename)

    try:
        with open(temp_pdf_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        temp_output_dir = os.path.join(temp_dir, "output")
        os.makedirs(temp_output_dir, exist_ok=True)

        print("Performing OCR...")
        try:
            ocr_page_results = process_pdf_with_fallback(temp_pdf_path, temp_output_dir)
        except ValueError as e:
            raise HTTPException(
                status_code=400,
                detail=f"OCR failed: {str(e)}. The document may be image-based or poorly scanned, or no text was extracted."
            )

        total_extracted_text = "\n".join(
            [page["corrected_text"] for page in ocr_page_results]
        )

        if not total_extracted_text.strip():
            raise HTTPException(
                status_code=400, detail="No text extracted from the PDF after OCR."
            )

        formatted_ocr_page_results = [
            OCRPageResult(**res) for res in ocr_page_results
        ]
        ocr_response = OCRResponse(
            pages=formatted_ocr_page_results,
            total_extracted_text=total_extracted_text,
        )

        print(f"Sending extracted text to classification service at {CLASSIFICATION_SERVICE_URL}...")
        
        files = {"file": ("extracted_text.txt", io.StringIO(total_extracted_text), "text/plain")}
        
        classification_response = requests.post(
            CLASSIFICATION_SERVICE_URL, files=files, timeout=600
        )
        
        if not classification_response.ok:
            raise HTTPException(
                status_code=500,
                detail=f"Classification service error: {classification_response.text}"
            )

        classification_result = classification_response.json()
        
        if not classification_result:
            raise HTTPException(
                status_code=500,
                detail="Empty response from classification service"
            )
        
        print(f"Classification result: {classification_result}")
        
        parsed_classification_result = ClassificationResponse(**classification_result)

        return OCRAndClassificationResponse(
            ocr_results=ocr_response,
            classification_result=parsed_classification_result,
        )

    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=f"File error: {e}")
    except requests.exceptions.Timeout:
        raise HTTPException(
            status_code=504,
            detail="Classification service timeout"
        )
    except requests.exceptions.RequestException as e:
        error_detail = f"Failed to connect to classification service or received an error: {e}"
        if e.response is not None:
            error_detail += f" - Response: {e.response.text}"
        raise HTTPException(
            status_code=500, detail=f"Classification error: {error_detail}"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"An unexpected error occurred during OCR and classification: {e}",
        )
    finally:
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
