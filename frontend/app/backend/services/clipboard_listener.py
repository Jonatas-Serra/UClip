"""Stub do listener de clipboard.

Este módulo conterá a lógica para escutar mudanças no clipboard (texto e imagens).
No MVP usaremos polling simples ou integração com wl-clipboard/xclip dependendo do ambiente.
"""

from typing import Optional
import threading
import time
import logging

try:
    import pyperclip
except Exception:
    pyperclip = None

from backend.services.database_service import init_db, Clip

try:
    from PIL import Image
    PIL_AVAILABLE = True
except Exception:
    PIL_AVAILABLE = False

logger = logging.getLogger("uclip.clipboard_listener")
logger.addHandler(logging.NullHandler())


class ClipboardListener:
    """Listener com melhorias:

    - Ignora entradas vazias
    - Evita duplicatas comparando conteúdo
    - Suporte básico a imagens (quando Pillow e wl-clipboard/xclip estiverem disponíveis)
    - Logging e tratamento de exceções
    """

    def __init__(self, poll_interval: float = 0.5):
        self._running = False
        self._latest: Optional[str] = None
        self._interval = poll_interval
        self._thread: Optional[threading.Thread] = None

    def _get_text(self) -> Optional[str]:
        if not pyperclip:
            return None
        try:
            return pyperclip.paste()
        except Exception as e:
            logger.debug("pyperclip.paste() failed: %s", e)
            return None

    def _get_image(self) -> Optional[bytes]:
        # Try Wayland wl-paste first
        import shutil, subprocess

        wl = shutil.which("wl-paste")
        if wl:
            try:
                # --no-newline to avoid adding newlines, --type image/png to request PNG
                p = subprocess.run([wl, "--no-newline", "--type", "image/png", "-"], capture_output=True, check=False)
                if p.returncode == 0 and p.stdout:
                    return p.stdout
            except Exception as e:
                logger.debug("wl-paste failed: %s", e)

        # Fallback for X11: try xclip or xsel
        xclip = shutil.which("xclip") or shutil.which("xsel")
        if xclip:
            try:
                if shutil.which("xclip"):
                    p = subprocess.run(["xclip", "-selection", "clipboard", "-t", "image/png", "-o"], capture_output=True, check=False)
                else:
                    p = subprocess.run(["xsel", "--clipboard", "--output", "--mime-type=image/png"], capture_output=True, check=False)
                if p.returncode == 0 and p.stdout:
                    return p.stdout
            except Exception as e:
                logger.debug("xclip/xsel failed: %s", e)

        return None

    def _run(self):
        SessionLocal = init_db()
        session = None
        try:
            session = SessionLocal()
            while self._running:
                try:
                    text = self._get_text()
                    if text:
                        text = text.strip()
                    # Prefer text if present
                    if text:
                        if text == self._latest:
                            # duplicate
                            logger.debug("Duplicate clipboard text ignored")
                        else:
                            self._latest = text
                            clip = Clip(content=text, mime="text/plain")
                            session.add(clip)
                            session.commit()
                            logger.info("Saved clip text (len=%d)", len(text))
                    else:
                        # try image
                        img_bytes = self._get_image()
                        if img_bytes:
                            # store image as base64 to keep schema simple for now
                            import base64

                            b64 = base64.b64encode(img_bytes).decode("ascii")
                            # save to disk
                            from backend.services.database_service import ensure_images_dir
                            import os, hashlib

                            images_dir = ensure_images_dir()
                            # name file by hash
                            h = hashlib.sha256(img_bytes).hexdigest()[:16]
                            filename = f"img_{h}.png"
                            file_path = os.path.join(images_dir, filename)
                            if not os.path.exists(file_path):
                                try:
                                    with open(file_path, "wb") as f:
                                        f.write(img_bytes)
                                except Exception as e:
                                    logger.exception("Failed to write image to disk: %s", e)
                                    continue

                            if file_path == self._latest:
                                logger.debug("Duplicate clipboard image ignored")
                            else:
                                self._latest = file_path
                                clip = Clip(content=file_path, mime="image/png")
                                session.add(clip)
                                session.commit()
                                logger.info("Saved clip image to %s", file_path)
                except Exception as e:
                    logger.exception("Error while polling clipboard: %s", e)
                time.sleep(self._interval)
        finally:
            if session:
                try:
                    session.close()
                except Exception:
                    pass

    def start(self):
        if self._running:
            return
        self._running = True
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()
        logger.info("Clipboard listener started")

    def stop(self):
        self._running = False
        if self._thread:
            self._thread.join(timeout=1.0)
        logger.info("Clipboard listener stopped")

    def get_latest(self) -> Optional[str]:
        return self._latest


