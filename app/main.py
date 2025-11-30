import os
from pathlib import Path

from fastapi import Depends, FastAPI, Header, HTTPException, Query
from fastapi.responses import FileResponse
from loguru import logger

app = FastAPI()

# Configuration
# We read these from environment variables set in docker-compose
# This will raise a KeyError if the variables are not set, causing the app to crash at startup (fail-fast)
API_KEY = os.environ["API_KEY"]
DATA_DIR = Path(os.environ.get("DATA_DIR", "/data"))

# Configure logger
# Rotation: 10 MB
logger.add("logs/access.log", rotation="10 MB")


async def verify_api_key(x_api_key: str = Header(...)):
    """
    Dependency that retrieves the 'x-api-key' header and validates it.
    """
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API Key")
    return x_api_key


@app.get("/")
def health_check():
    return {"status": "online", "message": "Data server is running"}


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
def list_files(api_key: str = Depends(verify_api_key)):
    """
    List all files in the data directory with their sizes.
    """
    files = []
    if DATA_DIR.exists():
        for file_path in DATA_DIR.iterdir():
            if file_path.is_file():
                files.append({"name": file_path.name, "size": file_path.stat().st_size})
    return {"files": files}
