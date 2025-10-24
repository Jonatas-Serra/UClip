# 📖 UClip — Complete Installation Guide (English)

Welcome! This guide shows you **how to install and use UClip** on your Linux computer.

**Table of Contents:**
- [What is UClip?](#what-is-uclip)
- [Quick Installation (2 minutes)](#-quick-installation-2-minutes)
- [Installation by Distribution](#-installation-by-distribution)
- [Backend Setup](#-backend-setup)
- [Register Global Shortcut](#-register-global-shortcut-superv)
- [Troubleshooting](#-troubleshooting)
- [Uninstallation](#-uninstallation)

---

## What is UClip?

**UClip** is a modern clipboard manager that:

✅ Automatically captures **text and images** when you copy  
✅ Stores on disk (never loses history)  
✅ Provides global shortcut **Super+V** to access history  
✅ Works on **X11 and Wayland**  
✅ No ads, no data sent (100% local)

## Arquitetura rápida

UClip funciona em duas partes:
1. **Backend** (Python): serviço que captura clips, armazena em DB SQLite e sirve via API REST
2. **Frontend** (Electron): interface gráfica que mostra clips, permite copiar/colar

Você precisa **dos dois rodando** para que o app funcione completamente.

---

## 1. Pré-requisitos

### Dependências do sistema (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y \
  python3 python3-pip python3-venv \
  libsqlite3-dev \
  xclip \
  wl-clipboard \
  dconf-cli \
  libxcb-xfixes0 libxcb-xtest0
```

Se você usa Wayland (sway/hyprland):
```bash
sudo apt-get install -y swaymsg
```

### Dependências Python (backend)

O projeto já tem `requirements.txt`. Você pode usar a venv criada ou criar uma nova:

```bash
cd /caminho/para/UClip
python3 -m venv .venv
source .venv/bin/activate
pip install -r backend/requirements.txt
```

---

## 2. Instalação do AppImage

### Passo 1: Baixar e preparar o AppImage

```bash
# download (ou use o que já existe em frontend/dist/)
VERSION=0.1.14
cd ~/Downloads  # (ou seu diretório de downloads)
wget https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.AppImage
# ou, se já tiver o arquivo:
cp /caminho/para/frontend/dist/UClip-${VERSION}.AppImage ~/UClip.AppImage

# tornar executável
sudo apt install -y libfuse2  # necessário para Ubuntu/Pop!_OS 22.04+
chmod +x ~/UClip.AppImage
```

### Passo 2: Instalar globalmente (opcional, mas recomendado)

```bash
# copiar para /usr/local/bin/ (requer sudo para permanência)
sudo cp ~/UClip.AppImage /usr/local/bin/uclip
sudo chmod +x /usr/local/bin/uclip

# agora você pode rodar simplesmente: uclip
```

Ou, alternativa sem sudo (colocar em ~/.local/bin/):
```bash
mkdir -p ~/.local/bin
cp ~/UClip.AppImage ~/.local/bin/uclip
chmod +x ~/.local/bin/uclip
export PATH="~/.local/bin:$PATH"   # (adicione ao seu ~/.zshrc ou ~/.bashrc para permanência)
```

### Passo 3: Testar o AppImage

```bash
# executar diretamente
~/UClip.AppImage

# ou, se instalou em /usr/local/bin:
uclip
```

**Esperado**: Uma pequena janela com uma lista vazia aparece (o backend precisa estar rodando para capturar clips).

---

## 3. Iniciar o Backend

O **backend** é um serviço Python que:
- Captura texto/imagens da área de transferência
- Armazena em banco SQLite
- Fornece API REST que o Frontend (Electron) consulta

### Opção A: Executar manualmente (testes rápidos)

```bash
cd /caminho/para/UClip
source .venv/bin/activate

# inicia backend e listener (clipboard capture)
python3 scripts/run_local.sh
```

Isto executa dois processos em paralelo:
1. `uvicorn` (backend API na porta 8000)
2. `clipboard_listener` (captura de clips)

**Esperado**: Saída em terminal mostrando:
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
[Listener] Running clipboard listener...
```

Deixe esta janela aberta enquanto usa o UClip.

### Opção B: Instalar como serviço systemd (executar ao boot — opcional)

Se quiser que o backend inicie automaticamente quando você liga o computador:

#### Criar arquivo de serviço

```bash
sudo nano /etc/systemd/user/uclip-backend.service
```

Cole o conteúdo abaixo (ajuste `User=` e caminhos conforme necessário):

```ini
[Unit]
Description=UClip Backend Service
After=network.target

[Service]
Type=simple
User=seu_usuario_aqui
WorkingDirectory=/home/seu_usuario_aqui/Projetos/UClip
Environment="PATH=/home/seu_usuario_aqui/Projetos/UClip/.venv/bin"
ExecStart=/home/seu_usuario_aqui/Projetos/UClip/.venv/bin/python3 /home/seu_usuario_aqui/Projetos/UClip/scripts/run_local.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

#### Ativar e iniciar serviço

```bash
# recarregar systemd
systemctl --user daemon-reload

# ativar para iniciar ao boot
systemctl --user enable uclip-backend.service

# iniciar agora
systemctl --user start uclip-backend.service

# verificar status
systemctl --user status uclip-backend.service

# ver logs
journalctl --user -u uclip-backend.service -f
```

---

## 4. Registrar Atalho Global (Super+V)

Agora que o App + Backend estão prontos, você quer um **atalho** para abrir/ocultar o UClip rapidamente.

### Para GNOME (X11 ou GNOME on Wayland)

Execute este bloco de comandos (copie e cole no terminal):

```bash
EXECUTABLE="/usr/local/bin/uclip"  # ou o caminho onde você colocou o AppImage
NAME="UClip Toggle"
BINDING="<Super>v"

# obter lista atual de custom keybindings
current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# criar nova entrada (usar custom0; se já existir, incremente para custom1, custom2, etc)
new_binding_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

# adicionar à lista (Python para manipular com segurança)
updated=$(python3 - <<PY
import ast,sys
cur = sys.argv[1]
try:
    arr = ast.literal_eval(cur)
except Exception:
    arr = []
if not isinstance(arr, list):
    arr = []
if "$new_binding_path" not in arr:
    arr.append("$new_binding_path")
print(repr(arr))
PY
"$current")

# aplicar lista atualizada
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated"

# configurar o novo binding
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_binding_path name "$NAME"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_binding_path binding "$BINDING"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_binding_path command "$EXECUTABLE"

echo "✓ Atalho GNOME registrado: $BINDING -> $EXECUTABLE"
```

**Verificar se funcionou:**
```bash
gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command
# deve imprimir o caminho do executável
```

**Para remover o atalho depois:**
```bash
current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
updated=$(python3 - <<PY
import ast,sys
cur = sys.argv[1]
try:
    arr = ast.literal_eval(cur)
except Exception:
    arr = []
arr = [x for x in arr if 'custom0' not in x]
print(repr(arr))
PY
"$current")
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated"
```

### Para sway / hyprland (Wayland)

Adicione ao seu arquivo de configuração do sway (`~/.config/sway/config`):

```bash
# UClip toggle via Super+V
bindsym Mod4+v exec /usr/local/bin/uclip
```

Depois recarregue a configuração:
```bash
swaymsg reload
```

Agora Super+V deve abrir o UClip.

---

## 5. Testar o fluxo completo

1. **Inicie o backend** (terminal):
   ```bash
   cd ~/Projetos/UClip
   source .venv/bin/activate
   python3 scripts/run_local.sh
   ```

2. **Copie algo para a área de transferência**:
   ```bash
   echo "Hello UClip" | xclip -selection clipboard
   # ou simplesmente copie algo no seu editor/navegador
   ```

3. **Abra o UClip**:
   - Pressione Super+V (ou clique no AppImage)
   - A janela deve aparecer com o clip que você copiou

4. **Clique em um clip** para copiar de volta

**Se nada aparecer**: Verifique logs
```bash
tail -n 50 ~/.local/share/uclip/uclip.log  # (se houver)
journalctl --user -u uclip-backend.service -n 50  # se serviço
```

---

## 6. Troubleshooting

### "Atalho Super+V não funciona"
- **X11/GNOME**: execute o bloco de comandos do passo 4 (GNOME)
- **sway/hyprland**: adicione a linha ao seu config e recarregue
- **Wayland genérico**: atalhos globais nem sempre funcionam — alternativa é clicar no AppImage manualmente

### "AppImage não abre / crashes"
- Verifique se tem dependências instaladas:
  ```bash
  sudo apt-get install -y libxcb-xfixes0 libxcb-xtest0 libfuse2
  ```
- Verifique permissões:
  ```bash
  chmod +x ~/UClip.AppImage
  ```

### "Frontend mostra lista vazia"
- Certifique-se de que o **backend está rodando** (passo 3)
- Verifique a API:
  ```bash
  curl http://127.0.0.1:8000/api/clips
  # deve retornar um JSON (vazio ou com clips)
  ```

### "Backend não inicia / erros SQLite"
- Certifique-se de que a pasta `~/.local/share/uclip/` existe:
  ```bash
  mkdir -p ~/.local/share/uclip
  ```

### "Preciso desinstalar"
- Remova o AppImage:
  ```bash
  rm /usr/local/bin/uclip  # (ou ~/UClip.AppImage)
  ```
- Pare o serviço (se ativado):
  ```bash
  systemctl --user stop uclip-backend.service
  systemctl --user disable uclip-backend.service
  ```
- Remova dados (opcional):
  ```bash
  rm -rf ~/.local/share/uclip
  ```

---

## 7. Próximos passos (opcional)

- **Customizar atalho**: altere `<Super>v` para qualquer outro (ex.: `<Ctrl><Alt>c`)
- **Usar .deb**: instale via `VERSION=0.1.14 && sudo apt install -y ./UClip-${VERSION}.deb` (se preferir)
- **Relatar bugs**: abra issue no GitHub

---

**Dúvidas?** Verifique os logs ou abra uma issue!
