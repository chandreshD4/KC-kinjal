from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import yt_dlp

app = FastAPI(title="KC-Aradhana Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class DownloadRequest(BaseModel):
    url: str
    format_type: str = "audio"

@app.get("/")
def home():
    return {"status": "KC Server is Running Successfully!"}

@app.post("/get-link")
def get_download_link(request: DownloadRequest):
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'format': 'bestaudio/best' if request.format_type == "audio" else 'bestvideo+bestaudio/best',
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(request.url, download=False)
            download_url = info.get('url')
            if not download_url:
                formats = info.get('formats', [])
                if formats:
                    download_url = formats[-1].get('url')

            if download_url:
                return {
                    "success": True,
                    "title": info.get('title', 'Unknown Title'),
                    "download_url": download_url
                }
            else:
                raise HTTPException(status_code=400, detail="Could not extract direct link.")
                
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
