# 🚀 UClip — Quick Start Guide

[**Português →**](#português-br) | [**English →**](#english)

---

## Português (BR)

### ⚡ Instalação em 2 Minutos

#### 1. Baixar e executar

```bash
VERSION=0.1.14

# Opção A: AppImage (Recomendado)
wget -O ~/UClip.AppImage https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.AppImage
sudo apt install -y libfuse2
chmod +x ~/UClip.AppImage
~/UClip.AppImage

# Opção B: Pacote DEB
wget https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.deb
sudo apt install -y ./UClip-${VERSION}.deb && uclip
```

#### 2. Instalar backend

```bash
git clone https://github.com/Jonatas-Serra/UClip.git
cd UClip

python3 -m venv .venv && source .venv/bin/activate
pip install -r backend/requirements.txt

# Inicie em outro terminal:
python3 scripts/run_local.sh
```

#### 3. Pronto!

Pressione **Super+V** (Windows+V) para abrir o UClip 🎉

### 🎯 Uso Básico

| Ação | Como |
|------|------|
| **Abrir** | Super+V |
| **Pesquisar** | Digite na caixa de busca |
| **Copiar** | Clique no clip ou ↑↓ + Enter |
| **Deletar** | Selecione + Delete |
| **Trocar idioma** | Clique em 🌐 no menu |
| **Fechar** | Esc ou Super+V novamente |

### 📚 Documentação Completa

- [Guia de Instalação Completo](INSTALL.pt.md)
- [Guia de Uso Detalhado](USAGE.pt.md)
- [Adicionar Novos Idiomas](I18N_GUIDE.md)

---

## English

### ⚡ Installation in 2 Minutes

#### 1. Download and run

```bash
VERSION=0.1.14

# Option A: AppImage (Recommended)
wget -O ~/UClip.AppImage https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.AppImage
sudo apt install -y libfuse2
chmod +x ~/UClip.AppImage
~/UClip.AppImage

# Option B: DEB Package
wget https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.deb
sudo apt install -y ./UClip-${VERSION}.deb && uclip
```

#### 2. Install backend

```bash
git clone https://github.com/Jonatas-Serra/UClip.git
cd UClip

python3 -m venv .venv && source .venv/bin/activate
pip install -r backend/requirements.txt

# Start in another terminal:
python3 scripts/run_local.sh
```

#### 3. Done!

Press **Super+V** (Windows+V) to open UClip 🎉

### 🎯 Basic Usage

| Action | How |
|--------|-----|
| **Open** | Super+V |
| **Search** | Type in search box |
| **Copy** | Click clip or ↑↓ + Enter |
| **Delete** | Select + Delete |
| **Change language** | Click 🌐 in menu |
| **Close** | Esc or Super+V again |

### 📚 Full Documentation

- [Complete Installation Guide](INSTALL.md)
- [Detailed Usage Guide](USAGE.md)
- [Add New Languages](I18N_GUIDE.md)

---

## 🐛 Troubleshooting

**Frontend shows empty list?**
- Make sure backend is running: `systemctl --user status uclip-backend.service`

**Shortcut not working?**
- GNOME: Run installation script again
- Sway/Hyprland: Add to config and reload

**AppImage won't open?**
- Install libfuse2: `sudo apt-get install libfuse2`

For more help → [INSTALL.md](INSTALL.md)

---

*Version: 0.1.14 | October 2025*
