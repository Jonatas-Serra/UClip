# 📖 UClip — Guia Completo de Instalação (Português)

Bem-vindo! Este guia te mostra **como instalar e usar o UClip** no seu computador Linux.

**Índice:**
- [O que é UClip?](#o-que-é-uclip)
- [Instalação Rápida (2 minutos)](#-instalação-rápida-2-minutos)
- [Instalação por Distribuição](#-instalação-por-distribuição)
- [Configurar Backend](#-configurar-backend)
- [Registrar Atalho Global](#-registrar-atalho-global-supperv)
- [Troubleshooting](#-troubleshooting)
- [Desinstalação](#-desinstalação)

---

## O que é UClip?

**UClip** é um gerenciador de clipboard moderno que:

✅ Captura automaticamente **texto e imagens** ao copiar  
✅ Armazena no disco (nunca perde histórico)  
✅ Oferece atalho global **Super+V** para acessar histórico  
✅ Funciona em **X11 e Wayland**  
✅ Sem anúncios, sem dados enviados (100% local)

### Arquitetura

```
Your Computer
├─ Frontend (Interface Gráfica)
│  └─ Electron App (AppImage ou .deb)
├─ Backend (Serviço)
│  └─ Python + FastAPI (roda em background)
└─ Banco de Dados
   └─ SQLite (histórico de clips)
```

---

## ⚡ Instalação Rápida (2 minutos)

### Passo 1: Escolha seu método

#### A. **AppImage** (Recomendado - Sem instalação)
Melhor para: Testar primeiro, sem permissões de root

```bash
VERSION=0.1.14
# Baixar (ou use do seu navegador)
wget -O ~/UClip.AppImage https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.AppImage

# Tornar executável
sudo apt install -y libfuse2  # necessário para rodar AppImage em Ubuntu/Pop!_OS 22.04+
chmod +x ~/UClip.AppImage

# Executar
~/UClip.AppImage
```

#### B. **Pacote .deb** (Ubuntu/Debian - Instalação Permanente)
Melhor para: Uso permanente, acesso pelo menu

```bash
VERSION=0.1.14
# Baixar pacote
wget https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.deb

# Instalar
sudo apt install -y ./UClip-${VERSION}.deb

# Executar (agora disponível no menu de aplicações)
uclip
```

#### C. **Script Automático** (Tudo de uma vez)
Melhor para: Setup completo com backend

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jonatasserra/UClip/main/scripts/install.sh)
```

### Passo 2: Configure o Backend

O backend é o "serviço invisível" que captura seus clips.

```bash
# Clone o repositório (se não fez no script automático)
git clone https://github.com/Jonatas-Serra/UClip.git
cd UClip

# Crie ambiente virtual Python
python3 -m venv .venv
source .venv/bin/activate

# Instale dependências
pip install -r backend/requirements.txt
```

### Passo 3: Inicie o Backend

```bash
# Opção A: Temporário (para testes)
source .venv/bin/activate
python3 scripts/run_local.sh

# Opção B: Automático (melhor)
# Siga a seção "Backend como Serviço" abaixo
```

### Passo 4: Use o UClip

Pressione **Super+V** (ou Windows+V) para abrir! 🎉

---

## 🐧 Instalação por Distribuição

### Ubuntu / Linux Mint / Pop!_OS

#### Método 1: AppImage
```bash
VERSION=0.1.14
wget -O ~/UClip.AppImage https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.AppImage
sudo apt install -y libfuse2
chmod +x ~/UClip.AppImage
~/UClip.AppImage
```

#### Método 2: .deb (recomendado)
```bash
VERSION=0.1.14
wget https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.deb
sudo apt install -y ./UClip-${VERSION}.deb
```

#### Dependências do Sistema
```bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv xclip wl-clipboard libxcb-xtest0 libfuse2
```

---

### Debian 11+

```bash
# Adicione backports se necessário
echo "deb http://deb.debian.org/debian $(lsb_release -cs)-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
sudo apt-get update

# Instale pacote
VERSION=0.1.14
wget https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.deb
sudo apt install -y ./UClip-${VERSION}.deb

# Dependências
sudo apt-get install -y python3 python3-pip python3-venv libfuse2
```

---

### Fedora / RHEL / CentOS

```bash
# Dependências
sudo dnf install -y python3 python3-pip gcc-c++ libxcb libxcb-devel wl-clipboard

# Use AppImage (recomendado, pois .deb pode não funcionar)
VERSION=0.1.14
wget -O ~/UClip.AppImage https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.AppImage
chmod +x ~/UClip.AppImage
~/UClip.AppImage
```

---

### Arch Linux

```bash
# Use AppImage ou compile localmente
VERSION=0.1.14
wget -O ~/UClip.AppImage https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.AppImage
chmod +x ~/UClip.AppImage
~/UClip.AppImage

# Ou instale via AUR (se disponível)
# yay -S uclip-bin
```

---

## ⚙️ Configurar Backend

### Opção A: Backend Manual (para desenvolvimento/testes)

Use se quiser ver logs em tempo real:

```bash
cd ~/Projetos/UClip  # ajuste o caminho
source .venv/bin/activate
python3 scripts/run_local.sh
```

Deixe este terminal aberto. Você verá:
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
[Listener] Running clipboard listener...
```

---

### Opção B: Backend como Serviço (Automático)

Configure para iniciar automaticamente ao ligar o PC:

#### 1. Criar arquivo de serviço

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/uclip-backend.service
```

Cole o conteúdo (ajuste `YOUR_USERNAME` e `/home/` conforme necessário):

```ini
[Unit]
Description=UClip Backend Service
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME/Projetos/UClip
Environment="PATH=/home/YOUR_USERNAME/Projetos/UClip/.venv/bin"
ExecStart=/home/YOUR_USERNAME/Projetos/UClip/.venv/bin/python3 /home/YOUR_USERNAME/Projetos/UClip/scripts/run_local.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

#### 2. Ativar o serviço

```bash
# Recarregar systemd
systemctl --user daemon-reload

# Ativar (inicia ao boot)
systemctl --user enable uclip-backend.service

# Iniciar agora
systemctl --user start uclip-backend.service

# Verificar status
systemctl --user status uclip-backend.service

# Ver logs em tempo real
journalctl --user -u uclip-backend.service -f
```

#### 3. Parar o serviço (se necessário)

```bash
systemctl --user stop uclip-backend.service
systemctl --user disable uclip-backend.service
```

---

## 🎯 Registrar Atalho Global (Super+V)

Agora configure o atalho para abrir o UClip.

### Para GNOME (X11 ou GNOME on Wayland)

Copie e cole este comando completo no terminal:

```bash
# Ajuste o caminho se não estiver em /usr/local/bin/uclip
EXECUTABLE="/usr/local/bin/uclip"
NAME="UClip Toggle"
BINDING="<Super>v"

# Obter lista atual
current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# Criar nova entrada
new_binding_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

# Adicionar à lista
updated=$(python3 - <<'PY'
import ast, sys
try:
    arr = ast.literal_eval(sys.argv[1])
except:
    arr = []
if not isinstance(arr, list): arr = []
if sys.argv[2] not in arr: arr.append(sys.argv[2])
print(repr(arr))
PY
"$current" "$new_binding_path")

# Aplicar
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_binding_path" name "$NAME"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_binding_path" binding "$BINDING"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_binding_path" command "$EXECUTABLE"

echo "✅ Atalho GNOME registrado!"
```

**Verificar se funcionou:**
```bash
gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command
```

### Para KDE Plasma

```bash
# Abra as Configurações de Atalhos (System Settings > Shortcuts)
# Ou via terminal:
kglobalshortcuts --file KDE_SHORTCUTS --new-name "UClip Toggle" "uclip"
```

Ou manualmente:
1. Abra **System Settings** → **Shortcuts and Gestures** → **Custom Shortcuts**
2. Clique **Edit** → **New** → **Global Shortcut** → **Command/URL**
3. Nome: `UClip Toggle`
4. Comando: `/usr/local/bin/uclip` (ou o caminho do seu AppImage)
5. Atribua: `Super+V`

### Para Sway / Hyprland (Wayland)

#### Sway

Edite `~/.config/sway/config` e adicione:

```bash
bindsym $mod+v exec "/usr/local/bin/uclip"
```

Depois recarregue:
```bash
swaymsg reload
```

#### Hyprland

Edite `~/.config/hypr/hyprland.conf` e adicione:

```bash
bind = $mainMod, V, exec, /usr/local/bin/uclip
```

Depois recarregue ou reinicie.

### Para XFCE

1. Abra **Settings** → **Keyboard** → **Application Shortcuts**
2. Clique **Add**
3. Comando: `/usr/local/bin/uclip`
4. Clique no atalho e pressione **Super+V**

---

## 📋 Verificar Instalação

Teste se tudo está funcionando:

```bash
# 1. Verifica se backend está rodando
curl http://127.0.0.1:8000/api/clips

# Deve retornar JSON com lista de clips (vazia se nenhum foi capturado)
# [{"id": 1, "content": "...", "type": "text", ...}, ...]

# 2. Verifica se arquivo de banco de dados existe
ls -lh ~/.local/share/uclip/clipboard.db

# 3. Verifica se serviço systemd está ativo
systemctl --user status uclip-backend.service

# 4. Testa atalho
# Pressione Super+V - deve abrir a janela
```

---

## 🐛 Troubleshooting

### "AppImage não abre" / "AppImage not found"

```bash
# Solução 1: Instalar libfuse2
sudo apt-get install libfuse2

# Solução 2: Verificar permissões
chmod +x ~/UClip.AppImage
ls -l ~/UClip.AppImage  # deve mostrar 'x'

# Solução 3: Tentar executar com debug
./UClip.AppImage --verbose
```

---

### "Atalho não funciona em Wayland"

**GNOME + Wayland:**
```bash
# Reinstale o atalho
gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys
# Depois execute novamente o comando de registro
```

**Sway/Hyprland:**
- Verifique que editou o arquivo correto
- Use `$mod` (Alt_L ou Super_L conforme sua config)
- Recarregue o compositor: `swaymsg reload` ou reinicie

---

### "Frontend mostra lista vazia"

```bash
# 1. Verifique se backend está rodando
systemctl --user status uclip-backend.service

# Se inativo:
systemctl --user start uclip-backend.service

# 2. Verifique se há clips no banco
curl http://127.0.0.1:8000/api/clips | jq .

# 3. Copie algo (Ctrl+C)
echo "test" | xclip -selection clipboard

# 4. Abra UClip novamente (Super+V)
```

---

### "Permissão negada" ao executar AppImage

```bash
# Solução
chmod +x ~/UClip.AppImage
chmod +x /usr/local/bin/uclip  # se instalou globalmente
```

---

### "Banco de dados locked" (erro ao iniciar)

```bash
# Causa: outra instância está usando
# Solução 1: Feche todas as instâncias do UClip
pkill -f uclip

# Solução 2: Remova arquivo de lock
rm -f ~/.local/share/uclip/clipboard.db-wal
rm -f ~/.local/share/uclip/clipboard.db-shm

# Tente novamente
```

---

### "Python not found" / "No module named 'fastapi'"

```bash
# Verificar Python
python3 --version  # deve ser 3.8+

# Reinstalar requirements
cd ~/Projetos/UClip
source .venv/bin/activate
pip install --upgrade -r backend/requirements.txt
```

---

### "Clipboard capture not working" (não captura clips)

```bash
# 1. Verifique ferramenta de clipboard
which xclip  # em X11
which wl-copy  # em Wayland

# 2. Reinstale dependências
sudo apt-get install --reinstall xclip wl-clipboard

# 3. Teste manualmente
echo "test" | xclip -selection clipboard
xclip -selection clipboard -o  # deve imprimir "test"

# 4. Verifique logs do backend
journalctl --user -u uclip-backend.service -f
# Procure por erros de captura
```

---

## ❌ Desinstalação

### Se instalou via AppImage

```bash
# Remova o arquivo
rm ~/UClip.AppImage
rm /usr/local/bin/uclip  # se instalou globalmente

# Remova atalho GNOME (se aplicável)
gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys

# Remova dados (opcional)
rm -rf ~/.local/share/uclip/
```

### Se instalou via .deb

```bash
# Desinstale pacote
sudo dpkg --remove uclip-frontend

# Remova dados (opcional)
rm -rf ~/.local/share/uclip/
```

### Se instalou Backend como Serviço

```bash
# Parar serviço
systemctl --user stop uclip-backend.service
systemctl --user disable uclip-backend.service

# Remover arquivo
rm ~/.config/systemd/user/uclip-backend.service
systemctl --user daemon-reload

# Remover venv (opcional)
rm -rf ~/Projetos/UClip/.venv
```

---

## 📞 Precisa de Ajuda?

- 🐛 **Bug?** → [GitHub Issues](https://github.com/Jonatas-Serra/UClip/issues)
- 💬 **Dúvida?** → [GitHub Discussions](https://github.com/Jonatas-Serra/UClip/discussions)
- 📧 **Email** → jonatasserra@outlook.com

---

## 🎓 Próximos Passos

Agora que tem o UClip instalado:

1. ✅ Copie algo (Ctrl+C)
2. ✅ Pressione Super+V
3. ✅ Veja seu clip no histórico!
4. 📖 Leia [Guia de Uso](USAGE.pt.md) para dicas avançadas

---

*Última atualização: Outubro 2025*  
*Versão: 0.1.14*
