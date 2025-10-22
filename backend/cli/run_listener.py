"""Script para rodar o listener de clipboard manualmente.

Uso: python backend/cli/run_listener.py
"""
import signal
import time
import logging

from backend.services.clipboard_listener import ClipboardListener


def main():
    logging.basicConfig(level=logging.INFO)
    l = ClipboardListener()
    l.start()

    def _stop(signum, frame):
        l.stop()
        raise SystemExit(0)

    signal.signal(signal.SIGINT, _stop)
    signal.signal(signal.SIGTERM, _stop)

    try:
        while True:
            time.sleep(1)
    except SystemExit:
        pass


if __name__ == '__main__':
    main()
