"""Clipboard listener com detecção robusta para X11 e Wayland.

Estratégia:
- Sempre prioriza wl-paste (Wayland nativo), depois xclip/xsel (X11), e por
  último pyperclip como fallback.
- Polling com intervalo curto + dedup por hash do conteúdo, e não pela string,
  o que evita falsos negativos quando o usuário copia o mesmo texto duas vezes
  intencionalmente após algo diferente.
- Texto e imagem são consultados em CADA iteração — imagem não fica refém de
  "texto vazio". Algumas apps colocam texto placeholder junto da imagem.
- Logging detalhado em DEBUG; INFO só para eventos de captura.
"""

from typing import Optional, Tuple
import os
import shutil
import subprocess
import threading
import time
import hashlib
import logging

try:
    import pyperclip
except Exception:  # pragma: no cover
    pyperclip = None

from backend.services.database_service import init_db, Clip, ensure_images_dir

logger = logging.getLogger("uclip.clipboard_listener")
logger.addHandler(logging.NullHandler())

# Assinatura de um arquivo PNG. Usada para validar que o clipboard realmente
# contém uma imagem: xclip/xsel, ao receber o target image/png para um
# clipboard que só tem texto, devolvem o PRÓPRIO texto com returncode 0. Sem
# essa checagem, todo texto copiado seria salvo como um .png inválido.
_PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def _run(cmd: list, timeout: float = 1.5) -> Tuple[int, bytes]:
    """Executa comando e retorna (returncode, stdout). Engole exceções."""
    try:
        p = subprocess.run(cmd, capture_output=True, check=False, timeout=timeout)
        return p.returncode, p.stdout
    except Exception as e:
        logger.debug("comando %s falhou: %s", cmd[0] if cmd else "?", e)
        return -1, b""


class ClipboardListener:
    def __init__(self, poll_interval: float = 0.4):
        self._running = False
        self._interval = poll_interval
        self._thread: Optional[threading.Thread] = None
        self._last_text_hash: Optional[str] = None
        self._last_image_hash: Optional[str] = None
        # Detecta capacidades uma vez
        self._wl_paste = shutil.which("wl-paste")
        self._xclip = shutil.which("xclip")
        self._xsel = shutil.which("xsel")
        self._is_wayland = bool(os.environ.get("WAYLAND_DISPLAY"))
        logger.info(
            "Listener init: wayland=%s wl-paste=%s xclip=%s xsel=%s",
            self._is_wayland, bool(self._wl_paste), bool(self._xclip), bool(self._xsel),
        )

    # ---------------- getters ----------------
    def _get_text(self) -> Optional[str]:
        # Wayland: wl-paste -n (sem newline final)
        if self._wl_paste:
            rc, out = _run([self._wl_paste, "-n", "-t", "text/plain"])
            if rc == 0 and out:
                try:
                    return out.decode("utf-8", errors="replace")
                except Exception:
                    pass
        # X11: xclip
        if self._xclip:
            rc, out = _run([self._xclip, "-selection", "clipboard", "-o"])
            if rc == 0 and out:
                try:
                    return out.decode("utf-8", errors="replace")
                except Exception:
                    pass
        # X11: xsel
        if self._xsel:
            rc, out = _run([self._xsel, "--clipboard", "--output"])
            if rc == 0 and out:
                try:
                    return out.decode("utf-8", errors="replace")
                except Exception:
                    pass
        # Último recurso: pyperclip
        if pyperclip is not None:
            try:
                return pyperclip.paste()
            except Exception as e:
                logger.debug("pyperclip falhou: %s", e)
        return None

    def _get_image(self) -> Optional[bytes]:
        # Só consideramos imagem o que começa com a assinatura PNG. Isso impede
        # que texto retornado por xclip/xsel (que ignoram o target solicitado)
        # seja salvo como imagem — o que fazia todo texto copiado virar um .png
        # inválido e nunca chegar em _get_text().
        if self._wl_paste:
            rc, out = _run([self._wl_paste, "-n", "-t", "image/png"])
            if rc == 0 and out.startswith(_PNG_MAGIC):
                return out
        if self._xclip:
            rc, out = _run([self._xclip, "-selection", "clipboard", "-t", "image/png", "-o"])
            if rc == 0 and out.startswith(_PNG_MAGIC):
                return out
        if self._xsel:
            rc, out = _run([self._xsel, "--clipboard", "--output", "--mime-type=image/png"])
            if rc == 0 and out.startswith(_PNG_MAGIC):
                return out
        return None

    # ---------------- persist ----------------
    def _save_text(self, session, text: str):
        text = text.strip()
        if not text:
            return
        h = hashlib.sha256(text.encode("utf-8", errors="replace")).hexdigest()
        if h == self._last_text_hash:
            return
        self._last_text_hash = h
        # também invalida image dedup (próxima imagem deve ser registrada)
        self._last_image_hash = None
        try:
            clip = Clip(content=text, mime="text/plain")
            session.add(clip)
            session.commit()
            logger.info("clip texto salvo (len=%d)", len(text))
        except Exception as e:
            session.rollback()
            logger.exception("falha ao salvar texto: %s", e)

    def _save_image(self, session, img_bytes: bytes):
        h_full = hashlib.sha256(img_bytes).hexdigest()
        if h_full == self._last_image_hash:
            return
        self._last_image_hash = h_full
        self._last_text_hash = None  # idem inverso
        filename = f"img_{h_full[:16]}.png"
        images_dir = ensure_images_dir()
        file_path = os.path.join(images_dir, filename)
        if not os.path.exists(file_path):
            try:
                with open(file_path, "wb") as f:
                    f.write(img_bytes)
            except Exception as e:
                logger.exception("falha ao gravar imagem em disco: %s", e)
                return
        try:
            # Importante: guardamos apenas o filename, não o path absoluto.
            # Isso evita inconsistências entre processos com HOME diferente.
            clip = Clip(content=filename, mime="image/png")
            session.add(clip)
            session.commit()
            logger.info("clip imagem salvo: %s", filename)
        except Exception as e:
            session.rollback()
            logger.exception("falha ao salvar registro de imagem: %s", e)

    # ---------------- loop ----------------
    def _run_loop(self):
        SessionLocal = init_db()
        session = SessionLocal()
        try:
            while self._running:
                try:
                    # Tenta imagem primeiro: se há imagem no clipboard, normalmente
                    # vem com texto vazio ou placeholder. Mas algumas apps duplicam
                    # como base64 em texto — checar imagem antes evita esse caso.
                    img = self._get_image()
                    if img:
                        self._save_image(session, img)
                    else:
                        text = self._get_text()
                        if text:
                            self._save_text(session, text)
                except Exception as e:
                    logger.exception("erro no loop: %s", e)
                time.sleep(self._interval)
        finally:
            try:
                session.close()
            except Exception:
                pass

    def start(self):
        if self._running:
            return
        self._running = True
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()
        logger.info("Clipboard listener started (interval=%.2fs)", self._interval)

    def stop(self):
        self._running = False
        if self._thread:
            self._thread.join(timeout=2.0)
        logger.info("Clipboard listener stopped")
