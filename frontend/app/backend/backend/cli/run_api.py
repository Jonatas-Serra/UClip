"""Simple runner to start the FastAPI app with uvicorn.

Usage: python backend/cli/run_api.py
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

import uvicorn


if __name__ == '__main__':
    uvicorn.run("backend.app:app", host="127.0.0.1", port=8001, reload=True)
