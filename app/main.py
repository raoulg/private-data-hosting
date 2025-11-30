import os
import tempfile
import zipfile
from pathlib import Path
from typing import List

import aiofiles
from fastapi import (BackgroundTasks, Depends, FastAPI, File, Header,
                     HTTPException, Query, UploadFile)
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from loguru import logger
from pydantic import BaseModel

app = FastAPI()

# Configuration
# We read these from environment variables set in docker-compose
# This will raise a KeyError if the variables are not set, causing the app to crash at startup (fail-fast)
API_KEY = os.environ["API_KEY"]
DATA_DIR = Path(os.environ.get("DATA_DIR", "/data"))
ALLOW_UPLOAD = os.environ.get("ALLOW_UPLOAD", "false").lower() == "true"

# Configure logger
# Rotation: 10 MB
logger.add("logs/access.log", rotation="10 MB")


class DownloadRequest(BaseModel):
    filenames: List[str]


async def verify_api_key(x_api_key: str = Header(None), api_key: str = Query(None)):
    """
    Dependency that retrieves the API key from 'x-api-key' header OR 'api_key' query param.
    """
    key = x_api_key or api_key
    if key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API Key")
    return key


# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
def read_root():
    """
    Serve the frontend GUI.
    """
    return FileResponse("static/index.html")


@app.get("/config")
def get_config(api_key: str = Depends(verify_api_key)):
    """
    Return server configuration.
    """
    return {"allow_upload": ALLOW_UPLOAD}


@app.get("/download")
def download_dataset(
    api_key: str = Depends(verify_api_key),
    user_email: str = Query(..., description="Email of the user downloading the data"),
    filename: str = Query(..., description="Specific filename to download"),
):
    """
    Secure endpoint. Only accessible if the correct x-api-key header is sent.
    Streams the file efficiently using FileResponse.
    """
    logger.info(f"Download requested by user: {user_email} for file: {filename}")
    file_path = DATA_DIR / filename

    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Dataset file not found on server.")

    # FileResponse automatically handles streaming for large files (500MB+)
    # It sets the correct Content-Disposition and Content-Type
    return FileResponse(
        path=file_path, filename=filename, media_type="application/octet-stream"
    )


@app.get("/list_files")
def list_files(
    api_key: str = Depends(verify_api_key),
    user_email: str = Query(
        ..., description="Email of the user accessing the file list"
    ),
):
    """
    List all files in the data directory with their sizes.
    Logs the access request as a TOS agreement.
    """
    logger.info(f"User {user_email} agreed to TOS and accessed file list.")
    files = []
    if DATA_DIR.exists():
        for file_path in DATA_DIR.iterdir():
            if file_path.is_file():
                if file_path.name == ".gitkeep":
                    continue
                files.append({"name": file_path.name, "size": file_path.stat().st_size})
    return {"files": files}


@app.post("/upload")
async def upload_file(
    files: List[UploadFile] = File(...),
    api_key: str = Depends(verify_api_key),
):
    """
    Upload multiple files to the server.
    """
    if not ALLOW_UPLOAD:
        raise HTTPException(
            status_code=403, detail="File upload is disabled on this server."
        )

    uploaded_files = []
    failed_files = []

    for file in files:
        if not file.filename:
            continue

        file_path = DATA_DIR / file.filename
        logger.info(f"Upload started: {file.filename}")

        try:
            async with aiofiles.open(file_path, "wb") as out_file:
                while content := await file.read(1024 * 1024):  # Read in 1MB chunks
                    await out_file.write(content)
            uploaded_files.append(file.filename)
            logger.info(f"Upload completed: {file.filename}")
        except Exception as e:
            logger.error(f"Upload failed for {file.filename}: {e}")
            failed_files.append(file.filename)

    if failed_files:
        return {
            "message": "Some files failed to upload",
            "uploaded": uploaded_files,
            "failed": failed_files,
        }

    return {"message": "All files uploaded successfully", "uploaded": uploaded_files}


@app.post("/download_zip")
def download_zip(
    request: DownloadRequest,
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key),
):
    """
    Create a zip archive of the requested files and return it.
    """
    if not request.filenames:
        raise HTTPException(status_code=400, detail="No filenames provided")

    # Create a temporary file for the zip
    temp_zip = tempfile.NamedTemporaryFile(delete=False, suffix=".zip")
    temp_zip.close()
    temp_zip_path = Path(temp_zip.name)

    try:
        with zipfile.ZipFile(temp_zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
            for filename in request.filenames:
                file_path = DATA_DIR / filename
                if file_path.exists() and file_path.is_file():
                    zipf.write(file_path, arcname=filename)
                else:
                    logger.warning(f"File not found for zipping: {filename}")
    except Exception as e:
        logger.error(f"Failed to create zip: {e}")
        if temp_zip_path.exists():
            os.remove(temp_zip_path)
        raise HTTPException(status_code=500, detail="Failed to create zip archive")

    # Schedule removal of the temp file after response is sent
    background_tasks.add_task(os.remove, temp_zip_path)

    return FileResponse(
        temp_zip_path, media_type="application/zip", filename="download.zip"
    )
