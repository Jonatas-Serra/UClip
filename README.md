<!-- Language Toggle: [Português](#português-br) | [English](#english) -->

# UClip — Gerenciador de Área de Transferência para Linux

Um gerenciador de clipboard moderno, rápido e fácil de usar para Linux. Captura automaticamente histórico de texto e imagens com um atalho global (Super+V).

[![Release](https://img.shields.io/github/v/release/Jonatas-Serra/UClip?style=flat-square)](https://github.com/Jonatas-Serra/UClip/releases)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-yellow?style=flat-square)](README.md)
[![Python](https://img.shields.io/badge/python-3.8+-blue?style=flat-square)](https://www.python.org/)
[![Node.js](https://img.shields.io/badge/node-16+-green?style=flat-square)](https://nodejs.org/)

---

## 📥 Download & Instalação Rápida

### 🐧 Ubuntu / Debian / Linux Mint

**Opção 1: Script automático completo** (Recomendado - Instala tudo)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Jonatas-Serra/UClip/main/scripts/install.sh)
```

**Opção 2: Instalação manual em 2 passos** (Frontend + Backend)

**Instalação em um comando** (recomendado - tudo automático!)
```bash
VERSION=0.2.2
wget https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.deb
sudo apt install -y ./UClip-${VERSION}.deb
```

✅ **É isso! Tudo configurado automaticamente:**
- ✔️ Backend (Python) instalado em `/opt/UClip`
- ✔️ Dependências Python instaladas
- ✔️ Banco de dados criado com permissões corretas
- ✔️ Serviços systemd criados e iniciados automaticamente
- ✔️ Listener configurado para autostart na sua sessão

**Próximo passo: Apenas execute:**
```bash
uclip
```

> 💡 **Pop!_OS 22.04+**: os comandos acima funcionam normalmente. Certifique-se de ter o pacote `libfuse2` instalado antes de rodar AppImage.

**Opção 2: AppImage** (versão portável, requer backend em separado)
```bash
VERSION=0.2.2
wget -O ~/UClip.AppImage https://github.com/Jonatas-Serra/UClip/releases/download/v${VERSION}/UClip-${VERSION}.AppImage
sudo apt install -y libfuse2  # necessário para rodar AppImage em Ubuntu/Pop!_OS recentes
chmod +x ~/UClip.AppImage

# Para usar AppImage com backend, siga as instruções de desenvolvimento abaixo
~/UClip.AppImage
```

### 🎯 Verificar Instalação

```bash
# ✓ Verificar se o frontend está instalado
which uclip

# ✓ Verificar se o backend está rodando (systemd services)
systemctl status uclip-backend.service
systemctl status uclip-listener.service

# ✓ Ver logs em tempo real
sudo journalctl -u uclip-backend.service -f
sudo journalctl -u uclip-listener.service -f

# ✓ Testar se o backend está respondendo
curl http://127.0.0.1:8001/health
```

---

## 🔧 Modo Desenvolvimento

Para desenvolver ou contribuir no UClip:

```bash
# Clonar repositório
git clone https://github.com/Jonatas-Serra/UClip.git
cd UClip

# 1. Backend (Python + FastAPI)
python3 -m venv .venv
source .venv/bin/activate
pip install -r backend/requirements.txt

# Iniciar backend em terminal separado
python3 backend/cli/run_api.py          # API em localhost:8001
# ou em outro terminal:
python3 backend/cli/run_listener.py     # Listener de clipboard

# 2. Frontend (React + Vite)
cd frontend
npm install
npm run dev                              # Vite dev server em localhost:5173

# 3. Em outro terminal, lance Electron
npm run electron:dev
```

**Pronto!** A aplicação rodará em modo desenvolvimento com hot reload.

---

## 🌍 Documentação

| PT-BR | English |
|--------|---------|
| [Guia Completo de Instalação](docs/INSTALL.pt.md) | [Complete Installation Guide](docs/INSTALL.md) |
| [Changelog](docs/CHANGELOG.md) | [Building Guide](docs/BUILD.md) |
| [Teste Rápido](docs/TESTE_RAPIDO.md) | [Quick Test](docs/QUICK_TEST.md) |

---

## ✨ Características

✅ **Captura Automática** — Texto e imagens capturados ao copiar  
✅ **Histórico Persistente** — Banco de dados SQLite local  
✅ **Atalho Global** — Super+V em X11 e Wayland  
✅ **Interface Limpa** — Baseada em React + Tailwind CSS  
✅ **Multilíngue** — Suporte a Português e Inglês  
✅ **Pesquisa Rápida** — Encontre clips antigos instantaneamente  
✅ **Cópia com Um Clique** — Recupere qualquer clip do histórico  
✅ **Sem Dependências Externas** — Funciona out-of-the-box

---

## 🏗️ Arquitetura

UClip é dividido em dois componentes principais:

```
┌─────────────────────────────────────────┐
│   Frontend (React + Electron)           │
│   • Interface gráfica bonita            │
│   • Atalho Super+V para abrir/ocultar   │
│   • Pesquisa de clips                   │
│   └─ Comunica com Backend via HTTP      │
└─────────────────────────────────────────┘
            ⬇️ API REST (localhost:8000)
┌─────────────────────────────────────────┐
│   Backend (Python + FastAPI)            │
│   • Escuta clipboard (X11/Wayland)      │
│   • Armazena em SQLite                  │
│   • Expõe dados via API REST            │
│   └─ Listener captura novos clips       │
└─────────────────────────────────────────┘
            ⬇️
┌─────────────────────────────────────────┐
│   Banco de Dados (SQLite)               │
│   • Histórico de texto e imagens        │
└─────────────────────────────────────────┘
```

**Backend Tech:**
- FastAPI, SQLAlchemy, pyperclip, Pillow

**Frontend Tech:**
- React, TypeScript, Tailwind CSS, Electron, Vite

---

## � Requisitos do Sistema

| Item | Versão | Notas |
|------|--------|-------|
| **OS** | Ubuntu 20.04+ | Debian, Linux Mint, Fedora |
| **Python** | 3.8+ | Para backend |
| **Node.js** | 16+ | Para desenvolvimento apenas |
| **Compilador** | gcc/clang | Automático em `apt-get install` |

---

## 🚀 Desenvolvimento

Para contribuir ou compilar localmente:

```bash
# Clone
git clone https://github.com/Jonatas-Serra/UClip.git
cd UClip

# Backend (Python)
python3 -m venv .venv && source .venv/bin/activate
pip install -r backend/requirements.txt
python3 backend/app.py  # API em http://localhost:8000

# Frontend (em outro terminal)
cd frontend
npm install
npm run dev  # Dev server em http://localhost:5173
# ou compilar:
npm run build && npm run prepack && npx electron-builder --linux
```

### 🧹 Limpeza de Dados de Desenvolvimento

**Importante**: Antes de criar um build ou release, sempre limpe os dados de desenvolvimento:

```bash
# Usando Makefile
make clean-dev-data

# Ou diretamente o script
./scripts/clean_dev_data.sh
```

Isso remove:
- `uclip.db*` — Banco de dados SQLite com dados de teste
- `images/` — Imagens copiadas durante desenvolvimento
- `__pycache__/` e `*.pyc` — Cache Python

> 💡 **Os scripts de build (`build_deb.sh` e `create_release.sh`) já fazem essa limpeza automaticamente!**

Veja [docs/BUILD.md](docs/BUILD.md) para guia completo de desenvolvimento.

---

## 🐛 Troubleshooting

| Problema | Solução |
|----------|---------|
| "AppImage não abre" | `sudo apt-get install libfuse2` |
| "Atalho não funciona em Wayland" | Execute instalador novamente ou [veja guia](docs/INSTALL.md) |
| "Permissão negada" no AppImage | `chmod +x ~/UClip.AppImage` |
| "Banco de dados locked" | Feche outra instância do UClip |
| "Clipboard vazio" | Certifique-se que backend está rodando |

Para mais detalhes → [docs/INSTALL.md](docs/INSTALL.md) | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 📄 Licença

[MIT License](LICENSE) — Livre para usar, modificar e distribuir.

---

## 🤝 Contribuições

Quer contribuir? Abra uma [issue](https://github.com/Jonatas-Serra/UClip/issues) ou [pull request](https://github.com/Jonatas-Serra/UClip/pulls)!

**Ideias para contribuições:**
- Suporte a mais idiomas
- Temas customizáveis
- Integração com outras aplicações
- Melhorias de performance
- Documentação

---

## 📞 Suporte

- 🐛 Encontrou um bug? [Abra uma issue](https://github.com/Jonatas-Serra/UClip/issues/new)
- 💬 Dúvidas? [Discussões](https://github.com/Jonatas-Serra/UClip/discussions)
- 📧 Email: [jonatasserra@outlook.com](mailto:jonatasserra@outlook.com)

---

## 🌟 Reconhecimentos

- Inspirado em Clipboard Managers (GNOME Clipboard, KDE Klipper)
- Comunidade Linux por ferramentas incríveis

**⭐ Se gostar, deixe uma estrela!**

---

## 📊 Status do Projeto

| Componente | Status | Nota |
|------------|--------|------|
| Backend API | ✅ Estável | Em produção |
| Frontend UI | ✅ Estável | Interface completada |
| Instalador | ✅ Automático | AppImage + .deb |
| Documentação | 🔄 Melhorando | Adicionando mais exemplos |
| i18n | 🚀 Em progresso | PT-BR e EN, expandindo |

---

*Última atualização: Outubro 2025*  
*Version: 0.2.0*
