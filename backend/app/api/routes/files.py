from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from pathlib import Path
from app.core.config import settings
import urllib.parse

router = APIRouter()

@router.get("/files/{file_path:path}")
def serve_file(file_path: str):
    """
    Serve files from the courses directory.
    The file_path is URL encoded, so we need to decode it.
    """
    try:
        # Decode the URL-encoded file path
        decoded_path = urllib.parse.unquote(file_path)
        
        # Construct full path
        full_path = Path(decoded_path)
        
        # Security check: ensure the file is within the courses root
        courses_root = Path(settings.COURSES_ROOT_PATH).resolve()
        resolved_file = full_path.resolve()
        
        # Check if file exists and is within courses root
        if not resolved_file.exists():
            raise HTTPException(status_code=404, detail="File not found")
        
        # Check if file is within the courses root directory
        try:
            resolved_file.relative_to(courses_root)
        except ValueError:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Return the file
        return FileResponse(
            path=str(resolved_file),
            media_type='application/octet-stream'
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error serving file: {str(e)}")


