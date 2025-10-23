"""Script para rodar o listener de clipboard manualmente.

Uso: python backend/cli/run_listener.py
"""
import signal
import time
import logging
import sys
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from backend.services.clipboard_listener import ClipboardListener

logger = logging.getLogger(__name__)


def main():
    logger.info("Starting UClip Clipboard Listener")
    l = ClipboardListener()
    l.start()

    def _stop(signum, frame):
        logger.info("Stopping UClip Clipboard Listener")
        l.stop()
        raise SystemExit(0)

    signal.signal(signal.SIGINT, _stop)
    signal.signal(signal.SIGTERM, _stop)

    try:
        while True:
            time.sleep(1)
    except SystemExit:
        pass
    except Exception as e:
        logger.error(f"Error in listener: {e}", exc_info=True)
        raise


if __name__ == '__main__':
    main()
