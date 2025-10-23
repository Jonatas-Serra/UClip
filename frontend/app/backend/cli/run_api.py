"""Simple runner to start the FastAPI app with uvicorn.

Usage: python backend/cli/run_api.py
"""
import sys
import os
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

import uvicorn


if __name__ == '__main__':
    # Disable reload when running from systemd
    use_reload = os.environ.get('UCLIP_DEV') == '1'
    
    logging.info("Starting UClip API Server on 127.0.0.1:8001")
    uvicorn.run("backend.app:app", host="127.0.0.1", port=8001, reload=use_reload, log_level="info")
