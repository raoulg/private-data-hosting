from fastapi import FastAPI, Depends, HTTPException, Header
from fastapi.responses import FileResponse
import os

app = FastAPI()

# Configuration
# We read these from environment variables set in docker-compose
API_KEY = os.getenv("API_KEY", "default-insecure-key")
DATA_FILE_NAME = os.getenv("DATA_FILE_NAME", "dataset.zip")
DATA_DIR = "/data"

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
def download_dataset(api_key: str = Depends(verify_api_key)):
    """
    Secure endpoint. Only accessible if the correct x-api-key header is sent.
    Streams the file efficiently using FileResponse.
    """
    file_path = os.path.join(DATA_DIR, DATA_FILE_NAME)
    
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Dataset file not found on server.")
    
    # FileResponse automatically handles streaming for large files (500MB+)
    # It sets the correct Content-Disposition and Content-Type
    return FileResponse(
        path=file_path, 
        filename=DATA_FILE_NAME,
        media_type='application/octet-stream'
    )